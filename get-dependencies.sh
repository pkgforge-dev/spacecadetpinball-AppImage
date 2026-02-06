#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
    cmake      \
    libdecor   \
    p7zip      \
    sdl2       \
    sdl2_mixer

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
make-aur-package spacecadetpinball-git

# If the application needs to be manually built that has to be done down here
echo "Making nightly build of spacecadetpinball..."
echo "---------------------------------------------------------------"
REPO="https://github.com/k4zmu2a/SpaceCadetPinball"
VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
git clone "$REPO" ./spacecadetpinball
echo "$VERSION" > ~/version

cd ./spacecadetpinball

wget https://archive.org/download/SpaceCadet_Plus95/Space_Cadet.rar
wget https://archive.org/download/win311_ftiltpball/FULLTILT.ZIP
7z x -y Space_Cadet.rar -oSpace_Cadet/
7z x -y 'FULLTILT.ZIP' -oFullTilt/ "CADET/CADET.DAT" "CADET/SOUND/*"

mkdir -p build && cd build
cmake .. \
    -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr
make -j$(nproc)
cd ..

mkdir -p /usr/lib/spacecadetpinball
# Install binary
mv -v bin/SpaceCadetPinball /usr/lib/spacecadetpinball/SpaceCadetPinball
# Install wrapper script
install -Dm0755 /dev/stdin "/usr/bin/SpaceCadetPinball" <<END
#!/bin/sh

# Configure soundfonts if not already configured
if [ -z "\$SDL_SOUNDFONTS" ]; then
  DEFAULT_SOUNDFONT="/usr/share/soundfonts/default.sf2"
  if [ -f "\$DEFAULT_SOUNDFONT" ]; then
    # Use default soundfont since it exists
    export SDL_SOUNDFONTS="\$DEFAULT_SOUNDFONT"
  else
    # Use first available soundfont
    export SDL_SOUNDFONTS="\$(find /usr/share/soundfonts -type f,l -print -quit 2> /dev/null)"
  fi
fi

# Run program in correct directory so it can find it's resources
cd /usr/lib/spacecadetpinball
exec ./SpaceCadetPinball "\$@"
END

# Install original game files
cd Space_Cadet
# Install resources
mv -v PINBALL.DAT *.MID Sounds/*.WAV /usr/lib/spacecadetpinball
# Install documentation
mv -v PINBALL.DOC TABLE.BMP /usr/share/doc/spacecadetpinball
cd ..

# Install full tilt game files
mv -v FullTilt/CADET/CADET.DAT "/usr/lib/spacecadetpinball"
mv -v FullTilt/CADET/SOUND/* "/usr/lib/spacecadetpinball/SOUND"

# Install icon
cp -rv SpaceCadetPinball/Icon_128x128.png /usr/lib/spacecadetpinball/SpaceCadetPinball.png
# Install desktop launcher
cp -rv Platform/Linux/SpaceCadetPinball.desktop /usr/share/applications
