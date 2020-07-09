#include "decoder.h"

Decoder::Decoder(QObject *parent)
    : QObject(parent),
      m_ptsClock(0),
      m_startTime(0),
      m_avStream(nullptr),
      m_avCodecCtx(nullptr),
      m_avFrame(nullptr)
{
    qRegisterMetaType<std::shared_ptr<Frame>>();
    m_avFrame = av_frame_alloc();
}

Decoder::~Decoder()
{
    if (m_avFrame) {
        av_frame_free(&m_avFrame);
    }

    closeCodec();
}

bool Decoder::openCodec(AVStream *stream)
{
    if (m_avCodecCtx || stream == nullptr) {
        return false;
    }

    AVCodec* codec = avcodec_find_decoder(stream->codecpar->codec_id);
    if (codec == NULL) {
        return false;
    }

    m_avCodecCtx = avcodec_alloc_context3(codec);
    if (!m_avCodecCtx) {
        return false;
    }

    if (avcodec_parameters_to_context(m_avCodecCtx, stream->codecpar) < 0) {
        closeCodec();
        return false;
    }

    if (avcodec_open2(m_avCodecCtx, codec, NULL) < 0) {
        closeCodec();
        return false;
    }

    m_avStream = stream;
    m_ptsClock = startPts();

    return true;
}

void Decoder::closeCodec()
{
    m_avStream = nullptr;

    if (m_avCodecCtx) {
        avcodec_free_context(&m_avCodecCtx);
    }
}

bool Decoder::codecIsOpen() const
{
    if (m_avCodecCtx && avcodec_is_open(m_avCodecCtx) > 0) {
        return true;
    }

    return false;
}

int Decoder::streamIndex() const
{
    if (m_avStream) {
        return m_avStream->index;
    }

    return -1;
}

qint64 Decoder::clock() const
{
    double pts = m_ptsClock - startPts();
    return m_startTime + pts * timeBase();
}

double Decoder::timeBase() const
{
    if (!m_avStream) {
        return 0;
    }

    return av_q2d(m_avStream->time_base) * 1000000;
}

qint64 Decoder::frameStartTime()
{
    double pts = framePts() - startPts();
    return m_startTime + pts * timeBase();
}

// WARNING: We should always return false when signal the frameFinished is not emitted!
bool Decoder::decode(const AVPacket &packet)
{
    int ret;

    if (!m_avCodecCtx) {
        return false;
    }

    // Submit the packet to the decoder
    ret = avcodec_send_packet(m_avCodecCtx, &packet);
    if (ret < 0) {
        return false;
    }

    // Get all the available frames from the decoder
    while (ret >= 0) {
        ret = avcodec_receive_frame(m_avCodecCtx, m_avFrame);
        if (ret < 0) {
            // Those two return values are special and mean there is no output
            // frame available, but there were no errors during decoding
            if (ret == AVERROR_EOF || ret == AVERROR(EAGAIN))
                return true;
            return false;
        }

        emit frameFinished(frame());

        av_frame_unref(m_avFrame);
    }

    return true;
}

qint64 Decoder::startPts() const
{
    if (!m_avStream || m_avStream->start_time == AV_NOPTS_VALUE) {
        return 0;
    }

    return m_avStream->start_time;
}

double Decoder::framePts()
{
    if (!m_avFrame || !m_avStream) {
        return 0;
    }

    double pts = m_avFrame->pkt_dts;
    double timeBase = av_q2d(m_avStream->time_base);

    if (pts == AV_NOPTS_VALUE) {
        pts = m_avFrame->pts;
    }
    if (pts == AV_NOPTS_VALUE) {
        pts = m_ptsClock + timeBase;
    }

    pts += m_avFrame->repeat_pict * (timeBase * 0.5);
    m_ptsClock = pts;

    return pts;
}

VideoDecoder::VideoDecoder(QObject *parent)
    : Decoder(parent),
      m_surfacePixelFormat(QVideoFrame::Format_Invalid)
{
}

void VideoDecoder::setSupportedPixelFormats(const QList<QVideoFrame::PixelFormat> &formats)
{
    if (codecIsOpen()) {
        m_surfacePixelFormat = VideoFormat::pixelFormatFromFFmpegFormat(m_avCodecCtx->pix_fmt);
        if (!formats.contains(m_surfacePixelFormat)) {
            m_surfacePixelFormat = QVideoFrame::Format_Invalid;

            // By default, we will need to convert an unsupported pixel format to first surface supported format
            for (int i = 0; i < formats.count(); ++i) {
                // This pixel format should also successfully match the ffmpeg format
                QVideoFrame::PixelFormat f = formats.value(i, QVideoFrame::Format_Invalid);
                if (VideoFormat::ffmpegFormatFromPixelFormat(f) != AV_PIX_FMT_NONE)  {
                    m_surfacePixelFormat = f;
                    break;
                }
            }
        }
    }
}

QVideoSurfaceFormat VideoDecoder::videoFormat() const
{
    QSize size(0, 0);

    if (codecIsOpen()) {
        size.setWidth(m_avCodecCtx->width);
        size.setHeight(m_avCodecCtx->height);
    }

    QVideoSurfaceFormat format(size, m_surfacePixelFormat);
    format.setPixelAspectRatio(pixelAspectRatio());
    return format;
}

QSize VideoDecoder::pixelAspectRatio() const
{
    if (codecIsOpen()) {
        if (m_avCodecCtx->sample_aspect_ratio.num) {
            return QSize(m_avCodecCtx->sample_aspect_ratio.num,
                         m_avCodecCtx->sample_aspect_ratio.den);
        }
    }

    return QSize(1, 1);
}

std::shared_ptr<Frame> VideoDecoder::frame()
{
    std::shared_ptr<VideoFrame> vf(new VideoFrame(frameStartTime()));
    vf->setPixelFormat(m_surfacePixelFormat);
    vf->fromAVFrame(m_avFrame);
    return vf;
}

AudioDecoder::AudioDecoder(QObject *parent)
    : Decoder(parent)
{
}

QAudioFormat AudioDecoder::audioFormat()
{
    QAudioFormat format;

    if (codecIsOpen()) {
        format.setSampleRate(m_avCodecCtx->sample_rate);
        format.setChannelCount(m_avCodecCtx->channels);
        format.setCodec("audio/pcm");
        format.setByteOrder(AV_NE(QAudioFormat::BigEndian, QAudioFormat::LittleEndian));
        format.setSampleType(AudioFormat::audioFormatFromFFmpegFormat(m_avCodecCtx->sample_fmt));
        format.setSampleSize(av_get_bytes_per_sample(m_avCodecCtx->sample_fmt) * 8);
    }

    return  format;
}

std::shared_ptr<Frame> AudioDecoder::frame()
{
    std::shared_ptr<AudioFrame> af(new AudioFrame(frameStartTime()));
    af->setAudioFormat(audioFormat());
    af->fromAVFrame(m_avFrame);
    return af;
}
