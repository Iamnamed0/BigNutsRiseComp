#!/bin/sh
cd include
if [ -d SFML-2.5.1 ];
then
        echo "Directory SFML-2.5.1 exists, overwrite?"
        read -p "[y/n]: " I
        if [ "$I" = "n" ];
        then
                echo "Quitting"
                exit
        fi
fi
rm -rf SFML-2.5.1
tar -xvf SFML-2.5.1.tar.gz
cd SFML-2.5.1

# Build for Linux
mkdir -p build && cd build
cmake .. -D BUILD_SHARED_LIBS=FALSE -D CMAKE_POLICY_VERSION_MINIMUM=3.5 && make
export SFML_DIR="$(pwd)"
cd ..

# Build for Windows (cross-compile)
mkdir -p build-windows && cd build-windows
cmake .. \
  -D BUILD_SHARED_LIBS=FALSE \
  -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -D CMAKE_TOOLCHAIN_FILE=../../../windows.cmake \
  -D OPENAL_INCLUDE_DIR=../extlibs/headers/AL \
  -D OPENAL_LIBRARY=../extlibs/libs-mingw/x64/libopenal32.a \
  && make

# Fix SFMLStaticTargets.cmake - correct hardcoded wrong lib paths
TARGETS=../build-windows/SFMLStaticTargets.cmake
sed -i 's|libs-mingw/x86/|libs-mingw/x64/|g' "$TARGETS"
# Fix Freetype target (was pointing to wrong lib after sed)
sed -i '/Freetype INTERFACE IMPORTED/{n;n;n;s|libFLAC.a|libfreetype.a|}' "$TARGETS"
# Fix Vorbis target (was all libFLAC.a)
sed -i 's|libFLAC.a;.*libFLAC.a;.*libFLAC.a;.*libFLAC.a|libvorbisfile.a;../extlibs/libs-mingw/x64/libvorbisenc.a;../extlibs/libs-mingw/x64/libvorbis.a;../extlibs/libs-mingw/x64/libogg.a|' "$TARGETS"

# Copy extlibs to where SFMLConfigDependencies.cmake searches
mkdir -p ../lib
cp ../extlibs/libs-mingw/x64/*.a ../lib/
cd ../lib && ln -sf libopenal32.a libopenal.a
cd ../../..

# Also copy to include/lib for the main project cmake search
mkdir -p lib
cp SFML-2.5.1/extlibs/libs-mingw/x64/*.a ../lib/ 2>/dev/null || true
mkdir -p ../include/lib
cp SFML-2.5.1/extlibs/libs-mingw/x64/*.a ../include/lib/
cd ../include/lib && ln -sf libopenal32.a libopenal.a
