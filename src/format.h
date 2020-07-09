#ifndef FORMAT_H
#define FORMAT_H

#include <QtCore>
#include <QVideoFrame>
#include <QAudioOutput>

extern "C" {
    #include <libavformat/avformat.h>
}


class VideoFormat
{
public:
    static AVPixelFormat normalizeFFmpegPixelFormat(AVPixelFormat avPixelFormat);
    static QVideoFrame::PixelFormat pixelFormatFromFFmpegFormat(AVPixelFormat avPixelFormat);
    static AVPixelFormat ffmpegFormatFromPixelFormat(QVideoFrame::PixelFormat pixelFormat);
};

class AudioFormat
{
public:
    static QAudioFormat::SampleType audioFormatFromFFmpegFormat(AVSampleFormat sampleFormat);
};


#endif // FORMAT_H
