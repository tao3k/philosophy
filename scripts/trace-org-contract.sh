#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
orgize_bin="${ORGIZE_BIN:-orgize}"
document="${1:-}"

if [ -z "${document}" ]; then
  echo "usage: just trace <document.org>" >&2
  exit 2
fi

if ! command -v "${orgize_bin}" >/dev/null 2>&1; then
  echo "philosophy: orgize executable not found; set ORGIZE_BIN=/path/to/orgize" >&2
  exit 127
fi

case "${document}" in
  /*) target="${document}" ;;
  *) target="${repository_root}/${document}" ;;
esac

"${orgize_bin}" contract workspace \
  --root "${repository_root}" \
  --policy "${repository_root}/org/workspace/philosophy.workspace.v1.org" \
  --org-contract-registry "${repository_root}/org/contracts/philosophy.v1.org" \
  --require-maintained "${target}" \
  >/dev/null

"${orgize_bin}" contract trace \
  --org-contract-registry "${repository_root}/org/contracts/philosophy.v1.org" \
  "${target}"
