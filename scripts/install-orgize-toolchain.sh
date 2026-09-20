#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
toolchain="${repository_root}/org/toolchain/philosophy.toolchain.v1.org"
orgize_repository="$(awk '/^:ORGIZE_REPOSITORY:/ { print $2; exit }' "${toolchain}")"
orgize_revision="$(awk '/^:ORGIZE_REVISION:/ { print $2; exit }' "${toolchain}")"
install_root="${ORGIZE_INSTALL_ROOT:-${HOME}/.local}"

cargo install --git "${orgize_repository}" --rev "${orgize_revision}" --locked --force --root "${install_root}" orgize
