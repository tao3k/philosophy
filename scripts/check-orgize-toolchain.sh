#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
toolchain="${repository_root}/org/toolchain/philosophy.toolchain.v1.org"
orgize_bin="${ORGIZE_BIN:-orgize}"
expected_revision="$(awk '/^:ORGIZE_REVISION:/ { print $2; exit }' "${toolchain}")"
actual_version="$("${orgize_bin}" version)"

if [[ "${actual_version}" != *"(${expected_revision})" ]]; then
  echo "philosophy: expected clean Orgize ${expected_revision}, found ${actual_version}" >&2
  echo "philosophy: run 'just toolchain-install' or set ORGIZE_BIN to the pinned binary" >&2
  exit 1
fi
