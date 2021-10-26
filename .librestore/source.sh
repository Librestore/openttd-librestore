#!/usr/bin/env bash

set -e
cd $(dirname $0)/..
DESTZIP="$1"

if [ "$TZ" = "" ]; then
  export TZ="America/New_York"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
fi

# Install dependencies
apt-get update
apt-get install -y sudo zip git build-essential cmake libsdl2-dev zlib1g-dev   \
                   liballegro4-dev libfontconfig-dev libicu-dev liblzma-dev    \
                   liblzo2-dev

# Fetch repo
git clone https://github.com/OpenTTD/OpenTTD || true
cd OpenTTD/
if [ ! "$LIBRESTORE_CHECKOUT" = "" ]; then
  git fetch
  git checkout "$LIBRESTORE_CHECKOUT"
fi

# Package source code
mkdir -p build.source
cd build.source
cmake -DCMAKE_BUILD_TYPE=Release ..
cpack --config CPackSourceConfig.cmake -G ZIP

# Move artifacts
mv -u $(ls bundles/*.zip | head -1) $DESTZIP
