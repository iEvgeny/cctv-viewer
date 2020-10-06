cmake_minimum_required(VERSION 3.14)

set(VER_MAJ 0)
set(VER_MIN 1)
set(VER_PAT 7)
set(REL_STATUS "alpha")

set(APP_NAME "CCTV Viewer")
set(ORG_NAME "T171RU")
set(ORG_DOMAIN "a71.ru")

set(VERSION "${VER_MAJ}.${VER_MIN}")

if(${VER_PAT} GREATER 0)
    set(VERSION "${VERSION}.${VER_PAT}")
endif()

project(cctv-viewer VERSION ${VERSION} HOMEPAGE_URL "https://github.com/iEvgeny/cctv-viewer" LANGUAGES C CXX)

if(DEFINED REL_STATUS)
    set(VERSION "${VERSION}-${REL_STATUS}")
endif()

add_definitions(-DAPP_NAME="${APP_NAME}" -DAPP_VERSION="${VERSION}" -DORG_NAME="${ORG_NAME}" -DORG_DOMAIN="${ORG_DOMAIN}")

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# QtCreator supports the following variables for Android, which are identical to qmake Android variables.
# Check http://doc.qt.io/qt-5/deployment-android.html for more information.
# They need to be set before the find_package(Qt5 ...) call.

#if(ANDROID)
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
#    if (ANDROID_ABI STREQUAL "armeabi-v7a")
#        set(ANDROID_EXTRA_LIBS
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libcrypto.so
#            ${CMAKE_CURRENT_SOURCE_DIR}/path/to/libssl.so)
#    endif()
#endif()

set(QT_LINK_DEPENDENCIES Core Quick Multimedia)
set(FFMPEG_LINK_DEPENDENCIES avformat avcodec avutil swscale swresample avdevice)

if (ANDROID)
    list(APPEND QT_LINK_DEPENDENCIES Svg)

    set(ANDROID_EXTRA_LIBS
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libavformat.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libavcodec.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libavutil.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libswscale.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libswresample.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libavdevice.so"
        "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib/libavfilter.so"
        )
endif()


find_package(QT NAMES Qt6 Qt5 COMPONENTS ${QT_LINK_DEPENDENCIES} LinguistTools REQUIRED)
find_package(Qt${QT_VERSION_MAJOR} 5.12 COMPONENTS ${QT_LINK_DEPENDENCIES} LinguistTools REQUIRED)

add_subdirectory(src/qmlav)

file(GLOB TS_FILES "${PROJECT_SOURCE_DIR}/res/translations/*.ts")

if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    qt5_add_resources(RESOURCES cctv-viewer.qrc)
else()
    find_package(Qt5QuickCompiler REQUIRED)
    qtquick_compiler_add_resources(RESOURCES cctv-viewer.qrc)
endif()

set(PROJ_FILES
    src/main.cpp
    src/singleapplication.h
    src/viewportslayoutmodel.cpp src/viewportslayoutmodel.h
    src/viewportslayoutscollectionmodel.cpp src/viewportslayoutscollectionmodel.h
    ${RESOURCES}
    ${QMLAV_FILES}
    ${TS_FILES}
    )

if (ANDROID)
    add_library(cctv-viewer SHARED ${PROJ_FILES})

    target_include_directories(cctv-viewer PRIVATE "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/include")
    target_link_directories(cctv-viewer PRIVATE "${CMAKE_SOURCE_DIR}/src/qmlav/3rd/FFmpeg/ffbuild/${ANDROID_ABI}/lib")
else()
    add_executable(cctv-viewer ${PROJ_FILES})
endif()

target_compile_definitions(cctv-viewer
    PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)

foreach (ITEM ${QT_LINK_DEPENDENCIES})
    target_link_libraries(cctv-viewer PRIVATE Qt${QT_VERSION_MAJOR}::${ITEM})
endforeach()
target_link_libraries(cctv-viewer PRIVATE ${FFMPEG_LINK_DEPENDENCIES})

set_directory_properties(PROPERTIES CLEAN_NO_CUSTOM true)
set_source_files_properties(${TS_FILES} PROPERTIES OUTPUT_LOCATION "${CMAKE_SOURCE_DIR}/res/translations")
qt5_create_translation(QM_FILES ${CMAKE_SOURCE_DIR}/src ${TS_FILES})

if (UNIX AND NOT ANDROID)
    include(GNUInstallDirs)
    set(CMAKE_INSTALL_PREFIX "/usr")
    install(TARGETS cctv-viewer DESTINATION "${CMAKE_INSTALL_BINDIR}")
    install(FILES "res/icons/cctv-viewer.svg" DESTINATION "/usr/share/pixmaps")
    install(FILES "cctv-viewer.desktop" DESTINATION "/usr/share/applications")
endif()
