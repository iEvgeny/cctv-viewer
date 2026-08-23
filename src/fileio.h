#ifndef FILEIO_H
#define FILEIO_H

#include <QObject>
#include <QString>
#include <QUrl>

// Minimal helper that lets QML read and write plain text files. Used to
// implement batch import/export of the sources/presets configuration.
class FileIO : public QObject
{
    Q_OBJECT

public:
    explicit FileIO(QObject *parent = nullptr) : QObject(parent) { }

    // Reads the whole file and returns its contents. On failure returns an
    // empty string and sets error().
    Q_INVOKABLE QString read(const QUrl &fileUrl);
    // Writes text to the file (truncating). Returns true on success.
    Q_INVOKABLE bool write(const QUrl &fileUrl, const QString &text);

    Q_INVOKABLE QString error() const { return m_error; }

private:
    static QString toLocalPath(const QUrl &fileUrl);

    QString m_error;
};

#endif // FILEIO_H
