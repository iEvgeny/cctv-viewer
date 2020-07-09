#ifndef FRAME_H
#define FRAME_H

#include <memory>
#include <QtCore>
#include <QVideoFrame>

#include "format.h"

extern "C" {
    #include <libavformat/avformat.h>
    #include <libavutil/imgutils.h>
    #include <libswscale/swscale.h>
    #include <libswresample/swresample.h>
}

class Frame
{
public:
    enum Type
    {
        TypeUnknown,
        TypeVideo,
        TypeAudio
    };

    Frame(qint64 startTime, Frame::Type type = Frame::TypeUnknown);
    virtual ~Frame() {}

    virtual bool isValid() const { return false; }
    virtual void fromAVFrame(AVFrame *avFrame) { Q_UNUSED(avFrame); }
    Frame::Type type() const { return m_type; }
    qint64 startTime() const { return m_startTime; }

private:
    Frame::Type m_type;
    qint64 m_startTime; // Absolute microsecond timestamp

    friend class VideoFrame;
    friend class AudioFrame;
};

class VideoFrame : public Frame
{
public:
    VideoFrame(qint64 startTime);

    virtual bool isValid() const override;
    virtual void fromAVFrame(AVFrame *avFrame) override;
    QVideoFrame::PixelFormat pixelFormat() const { return m_pixelFormat; }
    void setPixelFormat(QVideoFrame::PixelFormat format) { m_pixelFormat = format; }
    QVideoFrame& toVideoFrame() { return m_videoFrame; }
    operator QVideoFrame&() { return m_videoFrame; }

private:
    QVideoFrame m_videoFrame;
    QVideoFrame::PixelFormat m_pixelFormat;
};

class AudioFrame : public Frame
{
public:
    AudioFrame(qint64 startTime);
    virtual ~AudioFrame();

    virtual bool isValid() const override;
    virtual void fromAVFrame(AVFrame *avFrame) override;
    QAudioFormat audioFormat() const { return m_audioFormat; }
    void setAudioFormat(const QAudioFormat &format) { m_audioFormat = format; }
    char *data() const { return reinterpret_cast<char*>(m_data); }
    int dataSize() const { return m_dataSize; }

private:
    uint8_t *m_data;
    int m_dataSize;
    QAudioFormat m_audioFormat;
};

#endif // FRAME_H
