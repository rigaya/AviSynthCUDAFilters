#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
USER=$(git config --get user.name)
AVISYNTHP_VER=3.7.5

# nvccが見つからなければ、/usr/local/cuda/binをPATHに追加
if ! command -v nvcc &> /dev/null; then
    export PATH="/usr/local/cuda/bin:$PATH"
fi

# 注意: cmake 3.19.5未満では AviSynth+ の avs_core/CMakeLists.txt が
# 旧来の find_package(CUDA) 経路に入り、libcudart_static.a を生パスで
# リンクするだけになる。libcudart_static.a は shm_open / shm_unlink を
# 参照するが、glibc 2.34未満ではこれらがlibrt側にあるためリンクに失敗する。
# cmake 3.19.5以降なら CUDA::cudart_static (インポートターゲット) が
# rt / pthread / dl を INTERFACE 依存として持ち込むので問題ない。
# Ubuntu 20.04 の apt 版 cmake は 3.16.3 なので、pip 版を使うこと
# (docker/docker_ubuntu2004_cuda12 を参照)。
wget https://github.com/AviSynth/AviSynthPlus/archive/refs/tags/v${AVISYNTHP_VER}.tar.gz && \
tar -xzf v${AVISYNTHP_VER}.tar.gz && \
mv AviSynthPlus-${AVISYNTHP_VER} AviSynthPlus && \
cd AviSynthPlus && \
mkdir avisynth-build && \
cd avisynth-build && \
cmake ../ -G Ninja -DENABLE_CUDA=ON -DCMAKE_BUILD_TYPE=Release && \
ninja && \
    sudo checkinstall --maintainer="${USER}" --pkgname=avisynth --pkgversion="${AVISYNTHP_VER}" --backup=no --deldoc=yes --delspec=yes --deldesc=yes \
    --strip=yes --stripso=yes --addso=yes --fstrans=no --default ninja install && \
    "${SCRIPT_DIR}/deb2tarxz.sh" "$(ls avisynth_*.deb | head -1)"
