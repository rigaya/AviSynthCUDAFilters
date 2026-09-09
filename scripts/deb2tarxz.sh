#!/bin/sh
# checkinstallが生成したdebのペイロードから、配布用のtar.xzを生成する。
#
# debを扱えないディストリ (Fedora / RHEL系 / Arch / openSUSE など) 向けの配布物。
# 中身はdebと完全に同一で、展開先も同じ /usr/local 以下になる。
#   tar -C / -xf avisynth_<ver>_amd64_linux.tar.xz
# avisynth.pcのprefixがcmake configure時に絶対パスで焼き込まれるため、
# 展開先は /usr/local 固定とする。

set -e

DEB="$1"
if [ ! -f "${DEB}" ]; then
    echo "debファイルが見つかりません: ${DEB}"
    exit 1
fi

TARBALL=$(echo "${DEB}" | sed -e 's/\.deb$/.tar.xz/')

# 展開用の一時ディレクトリ。mktempで新規作成した領域のみを対象に後始末する。
STAGE=$(mktemp -d)
sudo dpkg-deb -x "${DEB}" "${STAGE}"
# 所有者をrootに正規化しておく (展開側でsudoを使う前提)
sudo tar -C "${STAGE}" --owner=0 --group=0 --numeric-owner -cJf "${TARBALL}" .
sudo chown "$(id -u):$(id -g)" "${TARBALL}"
sudo rm -rf "${STAGE}"

echo "${TARBALL}"
