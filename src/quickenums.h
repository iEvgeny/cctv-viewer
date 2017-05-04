#ifndef QUICKENUMS_H
#define QUICKENUMS_H

#include <QObject>

class QuickViewport : public QObject
{
    Q_OBJECT
    Q_ENUMS(Visible)

public:
    explicit QuickViewport(QObject *parent = 0) : QObject(parent) {}

    enum Visible {
        Hidden,
        Visible,
        Spanned
    };
};

#endif // QUICKENUMS_H
