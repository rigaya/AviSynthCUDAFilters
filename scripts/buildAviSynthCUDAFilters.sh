#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
VER=$(git describe --tags)
SHORTVER=$(echo $VER | sed -E 's/-g[0-9a-f]+$//')
#gitコマンドのユーザーを取得
USER=$(git config --get user.name)

# nvccが見つからなければ、/usr/local/cuda/binをPATHに追加
if ! command -v nvcc &> /dev/null; then
    export PATH="/usr/local/cuda/bin:$PATH"
fi

[ -d build ] || mkdir build && \
cd build && \
meson setup --buildtype release .. && \
ninja && \
    sudo checkinstall --pkgname=AviSynthCUDAFilters --maintainer="${USER}" --pkgversion="${SHORTVER}" --backup=no --deldoc=yes --delspec=yes --deldesc=yes \
    --strip=yes --stripso=yes --addso=yes --fstrans=no --default ninja install && \
    "${SCRIPT_DIR}/deb2tarxz.sh" "$(ls avisynthcudafilters_*.deb | head -1)"