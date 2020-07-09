#ifndef AVDECODER_H
#define AVDECODER_H

#include <QtCore>
#include <QVideoSurfaceFormat>
#include <QAudioOutput>

#include "frame.h"

extern "C" {
    #include <libavformat/avformat.h>
    #include <libavcodec/avcodec.h>
}

class Decoder : public QObject
{
    Q_OBJECT

public:
    Decoder(QObject *parent = nullptr);
    virtual ~Decoder();

    bool openCodec(AVStream *stream);
    void closeCodec();
    bool codecIsOpen() const;
    int streamIndex() const;
    qint64 clock() const;
    double timeBase() const;
    void setStartTime(qint64 startTime) { m_startTime = startTime; }
    qint64 frameStartTime();

    bool decode(const AVPacket &packet);

signals:
    void frameFinished(const std::shared_ptr<Frame> frame);

protected:
    qint64 startPts() const;
    double framePts();
    virtual std::shared_ptr<Frame> frame() = 0;

private:
    double m_ptsClock; // Equivalent to the PTS of the current frame
    qint64 m_startTime;
    AVStream *m_avStream;
    AVCodecContext *m_avCodecCtx;
    AVFrame *m_avFrame;

    friend class VideoDecoder;
    friend class AudioDecoder;
};
Q_DECLARE_METATYPE(std::shared_ptr<Frame>)

class VideoDecoder : public Decoder
{
    Q_OBJECT

public:
    VideoDecoder(QObject *parent = nullptr);

    void setSupportedPixelFormats(const QList<QVideoFrame::PixelFormat> &formats);
    QVideoSurfaceFormat videoFormat() const;

protected:
    QSize pixelAspectRatio() const;
    virtual std::shared_ptr<Frame> frame() override;

private:
    QVideoFrame::PixelFormat m_surfacePixelFormat;
};

class AudioDecoder : public Decoder
{
    Q_OBJECT

public:
    AudioDecoder(QObject *parent = nullptr);

    QAudioFormat audioFormat();

protected:
    virtual std::shared_ptr<Frame> frame() override;
};

#endif // AVDECODER_H
