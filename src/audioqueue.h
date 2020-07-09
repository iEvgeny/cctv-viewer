#ifndef AUDIOQUEUE_H
#define AUDIOQUEUE_H

#include <QtCore>

#include "frame.h"

class AudioQueue : public QIODevice
{
    Q_OBJECT

public:
    AudioQueue(QObject *parent = nullptr);
    virtual ~AudioQueue();

    virtual qint64 bytesAvailable() const override;
    virtual bool isSequential() const override;

    void push(const std::shared_ptr<AudioFrame> frame);

protected:
    virtual qint64 readData(char *data, qint64 maxSize) override;
    virtual qint64 writeData(const char *data, qint64 maxSize) override;

private:
    QByteArray m_buffer;
};

#endif // AUDIOQUEUE_H
