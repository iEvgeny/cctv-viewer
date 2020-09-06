VER_MAJ = 0
VER_MIN = 1
VER_PAT = 7
REL_STATUS = "alpha"

VERSION = "$${VER_MAJ}.$${VER_MIN}"

greaterThan(VER_PAT, 0) {
    VERSION = "$${VERSION}.$${VER_PAT}"
}
!isEmpty(REL_STATUS) {
    VERSION = "$${VERSION}-$${REL_STATUS}"
}

APP_NAME = "CCTV Viewer"
ORG_NAME = "T171RU"
ORG_DOMAIN = "a71.ru"

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
QT_MIN_MINOR_VERSION = 9
if (lessThan(QT_MAJOR_VERSION, $${QT_MIN_MAJOR_VERSION}) | lessThan(QT_MINOR_VERSION, $${QT_MIN_MINOR_VERSION})) {
    error("Cannot build $${APP_NAME} with Qt $${QT_VERSION}. Use at least Qt $${QT_MIN_MAJOR_VERSION}.$${QT_MIN_MINOR_VERSION}.0")
}

QT += qml quick multimedia

CONFIG += c++11 warn_on debug_and_release

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Refer to the documentation for the
# deprecated API to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

TEMPLATE = app

TARGET = cctv-viewer

DESTDIR = bin

HEADERS += \
    src/qmlav/src/qmlavaudioqueue.h \
    src/qmlav/src/qmlavdecoder.h \
    src/qmlav/src/qmlavdemuxer.h \
    src/qmlav/src/qmlavformat.h \
    src/qmlav/src/qmlavframe.h \
    src/qmlav/src/qmlavplayer.h \
    src/singleapplication.h \
    src/viewportslayoutmodel.h \
    src/viewportslayoutscollectionmodel.h

SOURCES += \
    src/main.cpp \
    src/qmlav/src/qmlavaudioqueue.cpp \
    src/qmlav/src/qmlavdecoder.cpp \
    src/qmlav/src/qmlavdemuxer.cpp \
    src/qmlav/src/qmlavformat.cpp \
    src/qmlav/src/qmlavframe.cpp \
    src/qmlav/src/qmlavplayer.cpp \
    src/viewportslayoutmodel.cpp \
    src/viewportslayoutscollectionmodel.cpp

RESOURCES += cctv-viewer.qrc

DISTFILES += res/translations/cctv-viewer_ru.ts

TRANSLATIONS += res/translations/cctv-viewer_ru.ts

OTHER_FILES += \
    $$files(src/qml/*.qml) \
    3rd/prebuild_ffmpeg.sh

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

LIBS += -lavcodec -lavdevice -lavformat -lavutil -lswresample -lswscale

# Static build for Android
android {
    QT += svg
    INCLUDEPATH += ./src/qmlav/3rd/FFmpeg
    DEPENDPATH += ./src/qmlav/3rd/FFmpeg
    for(abi, ANDROID_ABIS) {
        LIBS += -L$$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib
        ANDROID_EXTRA_LIBS = \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libavcodec.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libavdevice.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libavfilter.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libavformat.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libavutil.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libswresample.so \
            $$PWD/src/qmlav/3rd/FFmpeg/ffbuild/$${abi}/lib/libswscale.so
    }
}

# Rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: {
    target.path = /usr/bin
    icon.path = /usr/share/pixmaps
    icon.files += res/icons/$${TARGET}.svg
    desktop.path = /usr/share/applications
    desktop.files += $${TARGET}.desktop
}
!isEmpty(target.path): INSTALLS += target
!isEmpty(icon.path): INSTALLS += icon
!isEmpty(desktop.path): INSTALLS += desktop
