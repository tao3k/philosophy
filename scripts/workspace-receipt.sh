#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
orgize_bin="${ORGIZE_BIN:-orgize}"

exec "${orgize_bin}" contract workspace --summary-json \
  --root "${repository_root}" \
  --policy "${repository_root}/org/workspace/philosophy.workspace.v1.org" \
  --org-contract-registry "${repository_root}/org/contracts/philosophy.v1.org"
