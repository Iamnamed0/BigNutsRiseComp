#!/bin/bash
set -e

echo "=== Checking dependencies ==="
# Install required packages
sudo apt-get install -y \
  cmake make \
  mingw-w64 \
  libx11-dev libxrandr-dev libudev-dev \
  libglm-dev \
  p7zip-full zip

# Fix OpenGL32 symlink for MinGW
if [ ! -f /usr/x86_64-w64-mingw32/lib/libOpenGL32.a ]; then
  sudo ln -sf /usr/x86_64-w64-mingw32/lib/libopengl32.a \
              /usr/x86_64-w64-mingw32/lib/libOpenGL32.a
fi

# Copy GLM headers for MinGW
if [ ! -d /usr/x86_64-w64-mingw32/include/glm ]; then
  sudo cp -r /usr/include/glm /usr/x86_64-w64-mingw32/include/
fi

echo "=== Setting up SFML ==="
cd include

if [ -d SFML-2.5.1 ]; then
  echo "Directory SFML-2.5.1 exists, overwrite?"
  read -p "[y/n]: " I
  if [ "$I" = "n" ]; then
    echo "Quitting"
    exit
  fi
fi

rm -rf SFML-2.5.1
tar -xf SFML-2.5.1.tar.gz
cd SFML-2.5.1

echo "=== Building SFML for Linux ==="
mkdir -p build && cd build
cmake .. \
  -D BUILD_SHARED_LIBS=FALSE \
  -D CMAKE_POLICY_VERSION_MINIMUM=3.5
make
cd ..

echo "=== Building SFML for Windows ==="
mkdir -p build-windows && cd build-windows
cmake .. \
  -D BUILD_SHARED_LIBS=FALSE \
  -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -D CMAKE_TOOLCHAIN_FILE=../../../windows.cmake \
  -D OPENAL_INCLUDE_DIR=../extlibs/headers/AL \
  -D OPENAL_LIBRARY=../extlibs/libs-mingw/x64/libopenal32.a
make

echo "=== Fixing SFMLStaticTargets.cmake ==="
TARGETS="$(pwd)/SFMLStaticTargets.cmake"
sed -i 's|libs-mingw/x86/|libs-mingw/x64/|g' "$TARGETS"
# Fix Freetype wrongly pointing to libFLAC.a
sed -i '/add_library(Freetype/{n;n;n;n;s|libFLAC\.a|libfreetype.a|}' "$TARGETS"
# Fix Vorbis wrongly all pointing to libFLAC.a
EXTLIBS="$(cd ../extlibs/libs-mingw/x64 && pwd)"
sed -i "s|libFLAC\.a;.*libFLAC\.a;.*libFLAC\.a;.*libFLAC\.a|${EXTLIBS}/libvorbisfile.a;${EXTLIBS}/libvorbisenc.a;${EXTLIBS}/libvorbis.a;${EXTLIBS}/libogg.a|" "$TARGETS"

echo "=== Copying extlibs to search paths ==="
mkdir -p ../lib
cp ../extlibs/libs-mingw/x64/*.a ../lib/
cd ../lib && ln -sf libopenal32.a libopenal.a && cd ..

mkdir -p ../../lib 2>/dev/null || true
cp extlibs/libs-mingw/x64/*.a ../../lib/ 2>/dev/null || true
mkdir -p ../../include/lib
cp extlibs/libs-mingw/x64/*.a ../../include/lib/
cd ../../include/lib && ln -sf libopenal32.a libopenal.a

echo "=== Done! Run ./build.sh or ./build.sh --windows ==="
