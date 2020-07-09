#include "audioqueue.h"

AudioQueue::AudioQueue(QObject *parent)
    : QIODevice(parent)
{
    open(QIODevice::ReadOnly);
}

AudioQueue::~AudioQueue()
{
    close();
}

qint64 AudioQueue::bytesAvailable() const
{
    return m_buffer.size() + QIODevice::bytesAvailable();
}

bool AudioQueue::isSequential() const
{
    return true;
}

void AudioQueue::push(const std::shared_ptr<AudioFrame> frame)
{
    m_buffer.append(frame->data(), frame->dataSize());
}

qint64 AudioQueue::readData(char *data, qint64 maxSize)
{
    qint64 size = qMin(static_cast<qint64>(m_buffer.size()), maxSize);
    memcpy(data, m_buffer.constData(), size);
    m_buffer.remove(0, size);
    return size;
}

qint64 AudioQueue::writeData(const char *data, qint64 maxSize)
{
    Q_UNUSED(data);
    Q_UNUSED(maxSize);

    return 0;
}
