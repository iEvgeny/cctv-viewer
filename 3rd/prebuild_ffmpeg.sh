#!/bin/bash
#

SOURCE=./FFmpeg

TARGET_OS=android
ANDROID_API_VERSION=28
ANDROID_ABI=armeabi-v7a

# Available in runtime variables
ANDROID_NDK_HOST=linux-x86_64
ANDROID_NDK_ROOT=~/Android/Sdk/ndk/21.1.6352462

case ${ANDROID_ABI} in
    armeabi-v7a)
        ARCH=arm
        ;;
    arm64-v8a)
        ARCH=aarch64
        ;;
    x86)
        ARCH=i686
        ;;
    x86_64)
        ARCH=x86_64
        ;;
esac

CPU=${ARCH}
if [[ ${ARCH} == arm ]]; then
    EABI=eabi
    CPU=armv7a
fi

SYSROOT=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${ANDROID_NDK_HOST}/sysroot
CROSS_PREFIX=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${ANDROID_NDK_HOST}/bin/${ARCH}-linux-android${EABI}-
PREFIX=./ffbuild/${ANDROID_ABI}

cd ${SOURCE}

if [[ ! -d "${PREFIX}" ]]; then
    mkdir "${PREFIX}"
fi

./configure \
    --arch=${ARCH} \
    --cc=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${ANDROID_NDK_HOST}/bin/${CPU}-linux-android${EABI}${ANDROID_API_VERSION}-clang \
    --target-os=${TARGET_OS} \
    --sysroot="${SYSROOT}" \
    --cross-prefix="${CROSS_PREFIX}" \
    --prefix="${PREFIX}" \
    --enable-static \
    --enable-shared \
    --enable-cross-compile \
    --disable-asm \
    --disable-programs \
    --disable-doc

make clean
make -j$(nproc)
make install
