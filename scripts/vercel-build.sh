#!/bin/bash
# Vercel build script.
#
# Vercel's built-in Zola installer only fetches the glibc (gnu) release, and every
# Zola release since 0.20 is linked against glibc 2.35, which is newer than the
# build image provides. The musl release is fully static, so we download that
# ourselves and run it instead of relying on Vercel's ZOLA_VERSION install.
set -euo pipefail

ZOLA_MUSL_VERSION="${ZOLA_MUSL_VERSION:-0.22.1}"
BIN_DIR=".vercel/cache/zola-musl-v${ZOLA_MUSL_VERSION}"
URL="https://github.com/getzola/zola/releases/download/v${ZOLA_MUSL_VERSION}/zola-v${ZOLA_MUSL_VERSION}-x86_64-unknown-linux-musl.tar.gz"

if [ ! -x "${BIN_DIR}/zola" ]; then
  echo "Downloading Zola ${ZOLA_MUSL_VERSION} (musl)"
  mkdir -p "${BIN_DIR}"
  curl -sSL "${URL}" | tar xz -C "${BIN_DIR}"
fi

"${BIN_DIR}/zola" --version
npm run build
"${BIN_DIR}/zola" build

# Expose the tech category feed at the friendly /tech/feed.xml URL.
mkdir -p public/tech
cp public/categories/tech/feed.xml public/tech/feed.xml
