#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=/usr/lib/spacecadetpinball/SpaceCadetPinball.png
export DESKTOP=/usr/share/applications/SpaceCadetPinball.desktop
export DEPLOY_OPENGL=1

# Deploy dependencies
mkdir -p ./AppDir/bin
cp -r /usr/lib/spacecadetpinball/* ./AppDir/bin
quick-sharun ./AppDir/bin/*
echo 'SHARUN_WORKING_DIR=${SHARUN_DIR}/bin' >> ./AppDir/.env

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
