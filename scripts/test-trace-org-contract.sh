#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
trace="${repository_root}/scripts/trace-org-contract.sh"

"${trace}" cn/10-charter/10.10-epistemology-and-uncertainty.org >/dev/null

if "${trace}" org/contracts/philosophy.v1.org >/dev/null 2>&1; then
  echo "philosophy trace test: support document was accepted as maintained" >&2
  exit 1
fi

if "${trace}" cn/evil/deep/note.org >/dev/null 2>&1; then
  echo "philosophy trace test: undeclared nested target was accepted" >&2
  exit 1
fi

echo "philosophy trace target test: passed"
