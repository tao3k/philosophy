#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
"${repository_root}/scripts/check-orgize-toolchain.sh"
"${repository_root}/scripts/workspace-receipt.sh" > \
  "${repository_root}/org/toolchain/philosophy.workspace.receipt.v1.json"
