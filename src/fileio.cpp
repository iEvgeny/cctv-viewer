#include "fileio.h"

#include <QFile>
#include <QTextStream>

QString FileIO::toLocalPath(const QUrl &fileUrl)
{
    if (fileUrl.isLocalFile()) {
        return fileUrl.toLocalFile();
    }
    return fileUrl.toString();
}

QString FileIO::read(const QUrl &fileUrl)
{
    m_error.clear();

    QFile file(toLocalPath(fileUrl));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_error = file.errorString();
        return QString();
    }

    QTextStream stream(&file);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    stream.setCodec("UTF-8");
#endif
    const QString content = stream.readAll();
    file.close();

    return content;
}

bool FileIO::write(const QUrl &fileUrl, const QString &text)
{
    m_error.clear();

    QFile file(toLocalPath(fileUrl));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        m_error = file.errorString();
        return false;
    }

    QTextStream stream(&file);
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    stream.setCodec("UTF-8");
#endif
    stream << text;
    stream.flush();
    file.close();

    return true;
}
