#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
orgize_bin="${ORGIZE_BIN:-orgize}"
contract_registry="${repository_root}/org/contracts/philosophy.v1.org"

if ! command -v "${orgize_bin}" >/dev/null 2>&1; then
  echo "philosophy: orgize executable not found; set ORGIZE_BIN=/path/to/orgize" >&2
  exit 127
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "philosophy: jq is required to inspect Orgize contract receipts" >&2
  exit 127
fi

targets=()
while IFS= read -r org_file; do
  relative_path="${org_file#${repository_root}/}"
  case "${relative_path}" in
    README.org|cn/README.org|en/README.org|cn/*/*.org|en/*/*.org|org/contracts/*.org|org/templates/*.org)
      ;;
    *)
      echo "philosophy: Org file is outside the repository topology: ${relative_path}" >&2
      exit 1
      ;;
  esac

  case "${relative_path}" in
    README.org|cn/README.org|en/README.org|cn/*/*.org|en/*/*.org)
      targets+=("${org_file}")
      ;;
  esac
done < <(find "${repository_root}" -type f -name '*.org' -not -path '*/.git/*' | sort)

if [ "${#targets[@]}" -eq 0 ]; then
  echo "philosophy: no maintained Org documents found" >&2
  exit 1
fi

for org_file in "${targets[@]}"; do
  relative_path="${org_file#${repository_root}/}"
  if [ "${relative_path}" = "README.org" ]; then
    continue
  fi

  contract_line_count="$(grep -c '^:CONTRACT_ORG:' "${org_file}" || true)"
  if [ "${contract_line_count}" -ne 1 ]; then
    echo "philosophy: ${relative_path} must compose contracts on exactly one CONTRACT_ORG line" >&2
    exit 1
  fi

  semantic_id="$(sed -n 's/^:SEMANTIC_ID:[[:space:]]*//p' "${org_file}" | head -n 1)"
  counterpart_value="$(sed -n 's/^:COUNTERPART:[[:space:]]*//p' "${org_file}" | head -n 1)"
  if [ -z "${semantic_id}" ] || [ -z "${counterpart_value}" ]; then
    echo "philosophy: ${relative_path} must declare SEMANTIC_ID and COUNTERPART" >&2
    exit 1
  fi

  counterpart_dir="$(cd "$(dirname "${org_file}")" && cd "$(dirname "${counterpart_value}")" && pwd)"
  counterpart="${counterpart_dir}/$(basename "${counterpart_value}")"
  if [ ! -f "${counterpart}" ]; then
    echo "philosophy: ${relative_path} counterpart does not exist: ${counterpart_value}" >&2
    exit 1
  fi
  counterpart_semantic_id="$(sed -n 's/^:SEMANTIC_ID:[[:space:]]*//p' "${counterpart}" | head -n 1)"
  if [ "${semantic_id}" != "${counterpart_semantic_id}" ]; then
    echo "philosophy: ${relative_path} and ${counterpart_value} do not share SEMANTIC_ID" >&2
    exit 1
  fi
done

trace_receipt="$(mktemp "${TMPDIR:-/tmp}/philosophy-contract-trace.XXXXXX")"
trap 'rm -f "${trace_receipt}"' EXIT

"${orgize_bin}" contract trace \
  --org-contract-registry "${contract_registry}" \
  "${targets[@]}" > "${trace_receipt}"

failed_assertions="$(jq '[.files[].evaluations[].assertions[] | select(.status != "passed")] | length' "${trace_receipt}")"
if [ "${failed_assertions}" -ne 0 ]; then
  jq -r '.files[] as $file | $file.evaluations[] as $evaluation | $evaluation.assertions[] | select(.status != "passed") | "\($file.path): \($evaluation.contractId) / \(.assertionId) => \(.status)"' "${trace_receipt}" >&2
  exit 1
fi

evaluation_count="$(jq '[.files[].evaluations[]] | length' "${trace_receipt}")"
assertion_count="$(jq '[.files[].evaluations[].assertions[]] | length' "${trace_receipt}")"

"${orgize_bin}" lint --format compact \
  --org-contract-registry "${contract_registry}" \
  "${targets[@]}"

echo "philosophy: ${#targets[@]} documents, ${evaluation_count} contract evaluations, ${assertion_count} assertions passed"
