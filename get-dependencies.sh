#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm cmake sdl2 sdl2_mixer unrar

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano libdecor-mini

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

# If the application needs to be manually built that has to be done down here
echo "Building SpaceCadetPinball..."
echo "---------------------------------------------------------------"
echo "Downloading game data..."
wget --retry-connrefused --tries=30 \
	'https://archive.org/download/SpaceCadet_Plus95/Space_Cadet.rar' -O /tmp/Space_Cadet.rar
wget --retry-connrefused --tries=30 \
	'https://archive.org/download/win311_ftiltpball/FULLTILT.ZIP' -O /tmp/FULLTILT.ZIP

echo "Verifying checksums..."
echo "3cc5dfd914c2ac41b03f006c7ccbb59d6f9e4c32ecfd1906e718c8e47f130f4a  /tmp/Space_Cadet.rar" | sha256sum -c
echo "183a2219865b3f2199403928b817b7c967837ea6298de14fb8a379944c7b4599  /tmp/FULLTILT.ZIP" | sha256sum -c

unrar x -y /tmp/Space_Cadet.rar /tmp
mkdir -p /tmp/FullTilt
unzip -o /tmp/FULLTILT.ZIP "CADET/CADET.DAT" "CADET/SOUND/*" -d /tmp/FullTilt

mkdir -p ./AppDir/bin/SOUND

cp -v /tmp/Space_Cadet/PINBALL.DAT   ./AppDir/bin
cp -v /tmp/FullTilt/CADET/CADET.DAT  ./AppDir/bin
cp -v /tmp/FullTilt/CADET/SOUND/*    ./AppDir/bin
cp -v /tmp/Space_Cadet/*.MID         ./AppDir/bin
cp -v /tmp/Space_Cadet/Sounds/*.WAV  ./AppDir/bin

git clone https://github.com/k4zmu2a/SpaceCadetPinball.git ./SpaceCadetPinball && (
	cd ./SpaceCadetPinball

	# Determine to build nightly or stable
	if [ "${DEVEL_RELEASE-}" = 1 ]; then
		git rev-parse --short HEAD > ~/version
	else
		git fetch --tags origin
		TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|alpha\|beta' | head -1)
		git checkout "$TAG"
		echo "$TAG" > ~/version
	fi

	cmake -B ./build -Wno-dev -DCMAKE_BUILD_TYPE=Release
	cmake --build ./build -j$(nproc)
)

cp -v ./SpaceCadetPinball/bin/SpaceCadetPinball ./AppDir/bin/SpaceCadetPinball
