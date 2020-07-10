#include "demuxer.h"

InterruptCallback::InterruptCallback(qint64 timeout)
{
    callback = handler;
    opaque = this;
    m_timeout = timeout;
    m_interruptionRequested = false;
}

void InterruptCallback::startTimer()
{
    m_interruptionRequested = false;
    m_timer.start();
}

int InterruptCallback::handler(void *obj)
{
    InterruptCallback *cb = reinterpret_cast<InterruptCallback*>(obj);
    Q_ASSERT(cb);
    if (!cb) {
        return 0;
    }

    if (QThread::currentThread()->isInterruptionRequested() || cb->m_interruptionRequested) {
        return 1; // Interrupt
    }

    if (!cb->m_timer.isValid()) {
        cb->startTimer();
        return 0;
    }

    if (!cb->m_timer.hasExpired(cb->m_timeout)) {
        return 0;
    }

    return 1; // Interrupt
}

Demuxer::Demuxer(QObject *parent)
    : QObject(parent),
      m_realtime(false),
      m_lastTime(0),
      m_handledTime(0),
      m_formatCtx(nullptr),
      m_playbackState(QMediaPlayer::StoppedState),
      m_status(QMediaPlayer::UnknownMediaStatus),
      m_interruptionRequested(false)
{
    connect(&m_videoDecoder, &VideoDecoder::frameFinished, this, &Demuxer::frameFinished);
    connect(&m_audioDecoder, &AudioDecoder::frameFinished, this, &Demuxer::frameFinished);
}

Demuxer::~Demuxer()
{
    requestInterruption();

    if (m_formatCtx) {
        avformat_close_input(&m_formatCtx);
    }
}

void Demuxer::requestInterruption()
{
    m_interruptCallback.requestInterruption();
    m_interruptionRequested = true;
}

void Demuxer::load(const QUrl &url, const QVariantMap &options)
{
    int ret;
    QString source(url.toString());
    AVDictionary *avOptions = nullptr;

    if (m_formatCtx) {
        return;
    }

    if (source.isEmpty()) {
        setStatus(QMediaPlayer::NoMedia);
        setPlaybackState(QMediaPlayer::StoppedState);
        return;
    }

#ifndef FF_API_NEXT
    av_register_all();
    avformat_network_init();
#endif

    // TODO: Only Unix systems are supported
    if (url.isLocalFile()) {
        avdevice_register_all();
        source = url.toLocalFile();
    }
    m_realtime = isRealtime(url);

    setStatus(QMediaPlayer::LoadingMedia);
    setPlaybackState(QMediaPlayer::StoppedState);

    QMapIterator<QString, QVariant> i(options);
    while (i.hasNext()) {
        i.next();
        av_dict_set(&avOptions, i.key().toUtf8(), i.value().toString().toUtf8(), 0);
    }

    m_formatCtx = avformat_alloc_context();
    m_formatCtx->interrupt_callback = m_interruptCallback;

    m_interruptCallback.startTimer();
    ret = avformat_open_input(&m_formatCtx, source.toUtf8(), nullptr, &avOptions);
    if (ret < 0) {
        setStatus(QMediaPlayer::InvalidMedia);
        setPlaybackState(QMediaPlayer::StoppedState);
        return;
    }
    m_interruptCallback.stopTimer();

    m_interruptCallback.startTimer();
    ret = avformat_find_stream_info(m_formatCtx, nullptr);
    if (ret < 0) {
        setStatus(QMediaPlayer::InvalidMedia);
        setPlaybackState(QMediaPlayer::StoppedState);
        return;
    }
    m_interruptCallback.stopTimer();

    if (!findStreams()) {
        setStatus(QMediaPlayer::InvalidMedia);
        setPlaybackState(QMediaPlayer::StoppedState);
        return;
    }

    if (m_videoStreams.count() > 0) {
        // Open first video stream
        m_videoDecoder.openCodec(m_videoStreams.value(0));
    }
    if (m_audioStreams.count() > 0) {
        // Open first audio stream
        m_audioDecoder.openCodec(m_audioStreams.value(0));
    }
    if (!m_videoDecoder.codecIsOpen() && !m_audioDecoder.codecIsOpen()) {
        setStatus(QMediaPlayer::InvalidMedia);
        setPlaybackState(QMediaPlayer::StoppedState);
        return;
    }

    if (m_audioDecoder.codecIsOpen()) {
        emit audioFormatChanged(m_audioDecoder.audioFormat());
    }

    setStatus(QMediaPlayer::LoadedMedia);

    av_dict_free(&avOptions);
}

void Demuxer::setSupportedPixelFormats(const QList<QVideoFrame::PixelFormat> &formats)
{
    if (m_videoDecoder.codecIsOpen()) {
        m_videoDecoder.setSupportedPixelFormats(formats);
        emit videoFormatChanged(m_videoDecoder.videoFormat());
    }
}

#define MAX_QUEUE_DEPTH (3000000)  // 3 sec.

void Demuxer::run()
{
    int ret;

    if (m_playbackState != QMediaPlayer::StoppedState || m_status != QMediaPlayer::LoadedMedia) {
        return;
    }

    setPlaybackState(QMediaPlayer::PlayingState);

    // NOTE: We do not use buffering and video/audio sync to reduce latency
    setStatus(QMediaPlayer::BufferedMedia);

    qint64 startTime = av_gettime();
    m_videoDecoder.setStartTime(startTime);
    m_audioDecoder.setStartTime(startTime);

    while (!isInterruptionRequested()) {
        if (!m_formatCtx) {
            return;
        }

        av_init_packet(&m_packet);
        m_packet.data = nullptr;
        m_packet.size = 0;

        m_interruptCallback.startTimer();
        ret = av_read_frame(m_formatCtx, &m_packet);
        if (ret < 0) {
            if (ret == AVERROR_EOF) {
                setStatus(QMediaPlayer::EndOfMedia);
            } else {
                setStatus(QMediaPlayer::StalledMedia);
            }
            setPlaybackState(QMediaPlayer::StoppedState);
            av_packet_unref(&m_packet); // Important!
            break;
        }
        m_interruptCallback.stopTimer();

        // Protection of message queue depth (total memory usage)
        while (m_handledTime + MAX_QUEUE_DEPTH < m_lastTime) {
            if (isInterruptionRequested()) {
                break;
            }

            QThread::usleep(qMax(m_videoDecoder.timeBase(), 100.0));
            QCoreApplication::processEvents();
        }

        if (m_packet.stream_index == m_videoDecoder.streamIndex()) {
            m_videoDecoder.decode(m_packet);
            m_lastTime = m_videoDecoder.frameStartTime();
            // TODO: Temporary implementation
            if (!m_realtime) {
                while (m_videoDecoder.clock() > av_gettime()) {
                    QThread::usleep(m_videoDecoder.timeBase());
                }
            }
        } else if (m_packet.stream_index == m_audioDecoder.streamIndex()) {
            m_audioDecoder.decode(m_packet);
            m_lastTime = m_audioDecoder.frameStartTime();
            // TODO: Temporary implementation
            if (!m_realtime && !m_videoDecoder.codecIsOpen()) {
                while (m_audioDecoder.clock() > av_gettime()) {
                    QThread::usleep(m_audioDecoder.timeBase());
                }
            }
        } else {
            QThread::usleep(1);
        }

        av_packet_unref(&m_packet);

        QCoreApplication::processEvents();
    }
}

bool Demuxer::isRealtime(QUrl url)
{
    if (url.scheme() == "rtp"
            || url.scheme() == "srtp"
            || url.scheme().startsWith("rtmp") // rtmp{, e, s, t, te, ts}
            || url.scheme() == "rtsp"
            || url.scheme() == "udp") {
        return true;
    }

    return false;
}

bool Demuxer::isInterruptionRequested() const
{
    return m_playbackState != QMediaPlayer::PlayingState || m_interruptionRequested;
}

void Demuxer::setStatus(QMediaPlayer::MediaStatus status)
{
    if (m_status == status) {
        return;
    }

    m_status = status;

    emit statusChanged(status);
}

void Demuxer::setPlaybackState(const QMediaPlayer::State state)
{
    if (m_playbackState == state) {
        return;
    }

    m_playbackState = state;

    emit playbackStateChanged(state);
}

bool Demuxer::findStreams()
{
    m_videoStreams.clear();
    m_audioStreams.clear();

    if (!m_formatCtx) {
        return false;
    }

    AVMediaType type = AVMEDIA_TYPE_UNKNOWN;
    for (unsigned int i = 0; i < m_formatCtx->nb_streams; ++i) {
        type = m_formatCtx->streams[i]->codecpar->codec_type;
        if (type == AVMEDIA_TYPE_VIDEO) {
            m_videoStreams.append(m_formatCtx->streams[i]);
        } else if (type == AVMEDIA_TYPE_AUDIO) {
            m_audioStreams.append(m_formatCtx->streams[i]);
        }
    }

    if (m_videoStreams.isEmpty() && m_audioStreams.isEmpty()) {
        return false;
    }

    return true;
}
