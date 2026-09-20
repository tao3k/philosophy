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

case "${target}" in
  "${repository_root}"/README.org|"${repository_root}"/cn/README.org|"${repository_root}"/en/README.org|"${repository_root}"/cn/*/*.org|"${repository_root}"/en/*/*.org)
    ;;
  *)
    echo "philosophy: trace target is outside maintained content topology: ${document}" >&2
    exit 1
    ;;
esac

"${orgize_bin}" contract trace \
  --org-contract-registry "${repository_root}/org/contracts/philosophy.v1.org" \
  "${target}"
