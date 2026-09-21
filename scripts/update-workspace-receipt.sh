#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
receipt_path="${repository_root}/org/toolchain/philosophy.workspace.receipt.v1.json"
receipt_tmp="$(mktemp "${receipt_path}.tmp.XXXXXX")"
trap 'rm -f "${receipt_tmp}"' EXIT

"${repository_root}/scripts/check-orgize-toolchain.sh"
"${repository_root}/scripts/workspace-receipt.sh" >"${receipt_tmp}"
mv "${receipt_tmp}" "${receipt_path}"
