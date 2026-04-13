#!/bin/bash
WINDOWS=1
while [[ $# -gt 0 ]]; do
  case $1 in
    -w|--windows)
      WINDOWS=0
      shift # past argument
      shift # past value
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done


for file in CMakeFiles cmake_install.cmake CMakeCache.txt Makefile Jerboa
do
  if [ -d $file ];
  then
    rm -rf $file
  fi
  if [ -f $file ];
  then
    rm $file
  fi
done

echo $WINDOWS
if [[ $WINDOWS -eq 0 ]];
then 
  cmake . -D WINDOWS=ON -D CMAKE_TOOLCHAIN_FILE=./windows.cmake -D CMAKE_POLICY_VERSION_MINIMUM=3.5 -D SFML_STATIC_LIBRARIES=TRUE && make && \
  DATE=$(date +%Y-%m-%d_%H-%M-%S) && \
  mkdir -p "Jerboa-windows-${DATE}" && \
  cp Jerboa.exe "Jerboa-windows-${DATE}/" && \
  cp -r resources/ "Jerboa-windows-${DATE}/" && \
  cp include/SFML-2.5.1/extlibs/bin/x64/openal32.dll "Jerboa-windows-${DATE}/" && \
  zip -r "Jerboa-windows-${DATE}.zip" "Jerboa-windows-${DATE}/" && \
  rm -rf "Jerboa-windows-${DATE}" && \
  echo "Packaged: Jerboa-windows-${DATE}.zip"
else
  cmake . -D CMAKE_POLICY_VERSION_MINIMUM=3.5 && make
fi
