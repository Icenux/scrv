#!/usr/bin/env bash
# Makes the release files in dist/release/: scrv_all.deb, the Arch package scrv-VERSION-1-any.pkg.tar.zst and SHA256SUMS (signed later, locally, with
# icenux-app-sign-upload.sh; the signing key never reaches GitHub).
#
# Usage: bash packaging/package.sh VERSION     (needs nfpm in PATH; VERSION must match VERSION in ./scrv)
set -euo pipefail
umask 022
cd "$(dirname "$0")/.."

VERSION=${1:?usage: packaging/package.sh VERSION}
export VERSION
built=$(sed -n 's/^VERSION="\(.*\)"/\1/p' scrv | head -1)
[ "$built" = "$VERSION" ] || { echo "Version in scrv ($built) != $VERSION" >&2; exit 1; }
out=dist/release
rm -rf "$out" && mkdir -p "$out"

nfpm package --config packaging/nfpm.yaml --packager deb --target "$out/scrv_all.deb"
nfpm package --config packaging/nfpm.yaml --packager archlinux --target "$out/"
(cd "$out" && sha256sum scrv_all.deb scrv-*.pkg.tar.zst > SHA256SUMS)
ls -l "$out"
