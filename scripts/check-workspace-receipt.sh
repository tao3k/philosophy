#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
expected="${repository_root}/org/toolchain/philosophy.workspace.receipt.v1.json"
observed="$(mktemp)"
trap 'rm -f "${observed}"' EXIT
"${repository_root}/scripts/workspace-receipt.sh" >"${observed}"
diff -u "${expected}" "${observed}"
