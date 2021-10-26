#!/usr/bin/env bash

set -e
cd $(dirname $0)/..
DESTZIP="$1"
DESTDIR=$(mktemp -d)

if [ "$TZ" = "" ]; then
  export TZ="America/New_York"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

# Install dependencies
apt-get update
apt-get install -y sudo zip git python3 cmake curl build-essential pkg-config

git clone https://github.com/emscripten-core/emsdk.git || true
./emsdk/emsdk install 1.40.1
./emsdk/emsdk activate 1.40.1
sed -i "s/\#define MALLOC_ALIGNMENT ((size_t)(2 \* sizeof(void \*)))/#define MALLOC_ALIGNMENT 16/g" emsdk/upstream/emscripten/system/lib/dlmalloc.c # Fixes a bug in emscripten - see https://github.com/emscripten-core/emscripten/issues/13590
source ./emsdk/emsdk_env.sh

# Fetch repo
git clone https://github.com/OpenTTD/OpenTTD || true
cd OpenTTD/
if [ ! "$LIBRESTORE_CHECKOUT" = "" ]; then
  git fetch
  git checkout "$LIBRESTORE_CHECKOUT"
fi

# Build
mkdir -p build.tools
cd build.tools
cmake -DOPTION_TOOLS_ONLY=ON ..
make -j$(nproc)
cd ..

mkdir -p build.wasm
cd build.wasm
emcmake cmake -DHOST_BINARY_DIR=../build.tools ..
emmake make -j$(nproc)

# Move artifacts
mv -u openttd.html "$DESTDIR"/index.html
mv -u openttd.* "$DESTDIR"

cd "$DESTDIR"
zip "$DESTZIP" -r .
