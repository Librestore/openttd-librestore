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

# Build
mkdir -p build.gnu
cd build.gnu
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j$(nproc)
cpack -G STGZ

# Move artifacts
cd bundles
OUTPUT=$(ls ./*.sh | head -1)
mv -u "$OUTPUT" "$DESTDIR"

# Prepare install and launch scripts
echo "#!/usr/bin/env bash" > "$DESTDIR/install.sh"
echo "set -e" >> "$DESTDIR/install.sh"
echo "\$(dirname \"\$0\")/$OUTPUT --skip-license --exclude-subdir --prefix=\$1" >> "$DESTDIR/install.sh"
echo "cp \$(dirname \"\$0\")/run.sh \$1" >> "$DESTDIR/install.sh"
chmod +x "$DESTDIR/install.sh"

echo "#!/usr/bin/env bash" > "$DESTDIR/run.sh"
echo "set -e" >> "$DESTDIR/run.sh"
echo "\$(dirname \"\$0\")/games/openttd" >> "$DESTDIR/run.sh"
chmod +x "$DESTDIR/run.sh"

cd "$DESTDIR"
zip "$DESTZIP" -r .
