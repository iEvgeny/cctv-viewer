VER_MAJ = 0
VER_MIN = 1
VER_PAT = 0
REL_STATUS = "alpha"

VERSION = "$${VER_MAJ}.$${VER_MIN}"

greaterThan(VER_PAT, 0) {
    VERSION = "$${VERSION}.$${VER_PAT}"
}
!isEmpty(REL_STATUS) {
    VERSION = "$${VERSION} $${REL_STATUS}"
}

APP_NAME = "CCTV Viewer"
ORG_NAME = "T171RU"
ORG_DOMAIN = "https://t171.ru"

DEFINES += VER_MAJ=$${VER_MAJ} \
           VER_MIN=$${VER_MIN} \
           VER_PAT=$${VER_PAT} \
           \"REL_STATUS=\\\"$${REL_STATUS}\\\"\" \
           \"APP_VERSION=\\\"$${VERSION}\\\"\" \
           \"APP_NAME=\\\"$${APP_NAME}\\\"\" \
           \"ORG_NAME=\\\"$${ORG_NAME}\\\"\" \
           \"ORG_DOMAIN=\\\"$${ORG_DOMAIN}\\\"\"

# Check Qt version
QT_MIN_MAJOR_VERSION = 5
QT_MIN_MINOR_VERSION = 7
if (lessThan(QT_MAJOR_VERSION, $${QT_MIN_MAJOR_VERSION}) | lessThan(QT_MINOR_VERSION, $${QT_MIN_MINOR_VERSION})) {
    error("Cannot build $${APP_NAME} with Qt $${QT_VERSION}. Use at least Qt $${QT_MIN_MAJOR_VERSION}.$${QT_MIN_MINOR_VERSION}.0")
}

QT += qml quick

CONFIG += c++11 warn_on debug_and_release

TEMPLATE = app

TARGET = cctv-viewer

DESTDIR = bin

HEADERS += src/quickenums.h

SOURCES += src/main.cpp

RESOURCES += cctv-viewer.qrc

DISTFILES += \
    res/win32.rc \
    res/translations/cctv-viewer_ru.ts

TRANSLATIONS += res/translations/cctv-viewer_ru.ts

win32:RC_FILE = res/win32.rc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /usr/bin
!isEmpty(target.path): INSTALLS += target
