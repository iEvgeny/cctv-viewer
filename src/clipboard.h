#ifndef CLIPBOARD_H
#define CLIPBOARD_H

#include <QClipboard>
#include <QGuiApplication>

class Clipboard : public QObject
{
    Q_OBJECT

public:
    explicit Clipboard(QObject *parent = nullptr)
        : QObject{parent}
        , m_clipboard(QGuiApplication::clipboard()) { }

    Q_INVOKABLE QString text() const { return m_clipboard->text(); }
    Q_INVOKABLE void setText(const QString &text) {
        m_clipboard->setText(text);
    }

private:
    QClipboard *m_clipboard;
};

#endif // CLIPBOARD_H
