#include "format.h"

AVPixelFormat VideoFormat::normalizeFFmpegPixelFormat(AVPixelFormat avPixelFormat)
{
    // Replace deprecated AV_PIX_FMT_YUVJXXXP formats
    QMap<AVPixelFormat, AVPixelFormat> pixelFormatMap {
        {AV_PIX_FMT_YUVJ420P, AV_PIX_FMT_YUV420P},
        {AV_PIX_FMT_YUVJ422P, AV_PIX_FMT_YUV422P},
        {AV_PIX_FMT_YUVJ444P, AV_PIX_FMT_YUV444P},
        {AV_PIX_FMT_YUVJ440P, AV_PIX_FMT_YUV440P},
        {AV_PIX_FMT_YUVJ411P, AV_PIX_FMT_YUV411P}
    };

    // TODO: For the "sws_" functions family we need also to set color range. See sws_setColorspaceDetails()

    return pixelFormatMap.value(avPixelFormat, avPixelFormat);
}

QVideoFrame::PixelFormat VideoFormat::pixelFormatFromFFmpegFormat(AVPixelFormat avPixelFormat)
{
    // TODO:
    QMap<AVPixelFormat, QVideoFrame::PixelFormat> pixelFormatMap {
        {AV_PIX_FMT_ARGB, QVideoFrame::Format_ARGB32},
        {AV_PIX_FMT_0RGB, QVideoFrame::Format_ARGB32},
//        {, QVideoFrame::Format_ARGB32_Premultiplied},
        {AV_PIX_FMT_RGB32, QVideoFrame::Format_RGB32},
        {AV_PIX_FMT_RGB24, QVideoFrame::Format_RGB24},
        {AV_PIX_FMT_RGB565, QVideoFrame::Format_RGB565},
        {AV_PIX_FMT_RGB555, QVideoFrame::Format_RGB555},
//        {, QVideoFrame::Format_ARGB8565_Premultiplied},
        {AV_PIX_FMT_BGRA, QVideoFrame::Format_BGRA32},
        {AV_PIX_FMT_BGR0, QVideoFrame::Format_BGRA32},
//        {, QVideoFrame::Format_BGRA32_Premultiplied},
        {AV_PIX_FMT_BGR32, QVideoFrame::Format_BGR32},
        {AV_PIX_FMT_BGR24, QVideoFrame::Format_BGR24},
        {AV_PIX_FMT_BGR565, QVideoFrame::Format_BGR565},
        {AV_PIX_FMT_BGR555, QVideoFrame::Format_BGR555},
//        {, QVideoFrame::Format_BGRA5658_Premultiplied},
//        {, QVideoFrame::Format_AYUV444},
//        {, QVideoFrame::Format_AYUV444_Premultiplied},
//        {, QVideoFrame::Format_YUV444},
        {AV_PIX_FMT_YUV420P, QVideoFrame::Format_YUV420P},
        {AV_PIX_FMT_YUVJ420P, QVideoFrame::Format_YUV420P},
//        {, QVideoFrame::Format_YV12},
        {AV_PIX_FMT_UYVY422, QVideoFrame::Format_UYVY},
        {AV_PIX_FMT_YUYV422, QVideoFrame::Format_YUYV},
        {AV_PIX_FMT_NV12, QVideoFrame::Format_NV12},
        {AV_PIX_FMT_NV21, QVideoFrame::Format_NV21},
//        {, QVideoFrame::Format_IMC1},
//        {, QVideoFrame::Format_IMC2},
//        {, QVideoFrame::Format_IMC3},
//        {, QVideoFrame::Format_IMC4},
        {AV_PIX_FMT_GRAY8, QVideoFrame::Format_Y8},
        {AV_PIX_FMT_GRAY16LE, QVideoFrame::Format_Y16},
        {AV_PIX_FMT_YUVJ422P, QVideoFrame::Format_Jpeg}/*,
        {, QVideoFrame::Format_CameraRaw},
        {, QVideoFrame::Format_AdobeDng}*/
    };

    return pixelFormatMap.value(avPixelFormat, QVideoFrame::Format_Invalid);
}

AVPixelFormat VideoFormat::ffmpegFormatFromPixelFormat(QVideoFrame::PixelFormat pixelFormat)
{
    // TODO:
    QMap<QVideoFrame::PixelFormat, AVPixelFormat> pixelFormatMap {
        {QVideoFrame::Format_ARGB32, AV_PIX_FMT_ARGB},
//        {QVideoFrame::Format_ARGB32_Premultiplied, },
        {QVideoFrame::Format_RGB32, AV_PIX_FMT_RGB32},
        {QVideoFrame::Format_RGB24, AV_PIX_FMT_RGB24},
        {QVideoFrame::Format_RGB565, AV_PIX_FMT_RGB565},
        {QVideoFrame::Format_RGB555, AV_PIX_FMT_RGB555},
//        {QVideoFrame::Format_ARGB8565_Premultiplied, },
        {QVideoFrame::Format_BGRA32, AV_PIX_FMT_BGRA},
//        {QVideoFrame::Format_BGRA32_Premultiplied, },
        {QVideoFrame::Format_BGR32, AV_PIX_FMT_BGR32},
        {QVideoFrame::Format_BGR24, AV_PIX_FMT_BGR24},
        {QVideoFrame::Format_BGR565, AV_PIX_FMT_BGR565},
        {QVideoFrame::Format_BGR555, AV_PIX_FMT_BGR555},
//        {QVideoFrame::Format_BGRA5658_Premultiplied, },
//        {QVideoFrame::Format_AYUV444, },
//        {QVideoFrame::Format_AYUV444_Premultiplied, ,},
//        {QVideoFrame::Format_YUV444, ,},
        {QVideoFrame::Format_YUV420P, AV_PIX_FMT_YUV420P},
//        {QVideoFrame::Format_YV12, },
        {QVideoFrame::Format_UYVY, AV_PIX_FMT_UYVY422},
        {QVideoFrame::Format_YUYV, AV_PIX_FMT_YUYV422},
        {QVideoFrame::Format_NV12, AV_PIX_FMT_NV12},
        {QVideoFrame::Format_NV21, AV_PIX_FMT_NV21},
//        {QVideoFrame::Format_IMC1, },
//        {QVideoFrame::Format_IMC2, },
//        {QVideoFrame::Format_IMC3, },
//        {QVideoFrame::Format_IMC4, },
        {QVideoFrame::Format_Y8, AV_PIX_FMT_GRAY8},
        {QVideoFrame::Format_Y16, AV_PIX_FMT_GRAY16LE},
        {QVideoFrame::Format_Jpeg, AV_PIX_FMT_YUVJ422P}/*,
        {QVideoFrame::Format_CameraRaw, },
        {QVideoFrame::Format_AdobeDng, }*/
    };

    return pixelFormatMap.value(pixelFormat, AV_PIX_FMT_NONE);
}

QAudioFormat::SampleType AudioFormat::audioFormatFromFFmpegFormat(AVSampleFormat sampleFormat)
{
    QMap<AVSampleFormat, QAudioFormat::SampleType> sampleFormatMap {
        {AV_SAMPLE_FMT_U8, QAudioFormat::UnSignedInt}, // unsigned 8 bits
        {AV_SAMPLE_FMT_S16, QAudioFormat::QAudioFormat::SignedInt}, // signed 16 bits
        {AV_SAMPLE_FMT_S32, QAudioFormat::QAudioFormat::SignedInt}, // signed 32 bits
        {AV_SAMPLE_FMT_FLT, QAudioFormat::QAudioFormat::Float}, // float
        {AV_SAMPLE_FMT_DBL, QAudioFormat::QAudioFormat::Float}, // double

        {AV_SAMPLE_FMT_U8P, QAudioFormat::UnSignedInt}, // unsigned 8 bits, planar
        {AV_SAMPLE_FMT_S16P, QAudioFormat::SignedInt}, // signed 16 bits, planar
        {AV_SAMPLE_FMT_S32P, QAudioFormat::SignedInt}, // signed 32 bits, planar
        {AV_SAMPLE_FMT_FLTP, QAudioFormat::Float}, // float, planar
        {AV_SAMPLE_FMT_DBLP, QAudioFormat::Float}/*, // double, planar
        {AV_SAMPLE_FMT_S64, QAudioFormat::, }, // signed 64 bits
        {AV_SAMPLE_FMT_S64P, QAudioFormat::, } // signed 64 bits, planar*/
    };

    return sampleFormatMap.value(sampleFormat, QAudioFormat::Unknown);
}
