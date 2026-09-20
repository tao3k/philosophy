#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
orgize_bin="${ORGIZE_BIN:-orgize}"
fixture_parent="$(mktemp -d "${TMPDIR:-/tmp}/philosophy-contract-negative.XXXXXX")"
trap 'rm -rf "${fixture_parent}"' EXIT

make_fixture() {
  local name="$1"
  local root="${fixture_parent}/${name}"
  mkdir -p "${root}"
  cp "${repository_root}/README.org" "${root}/"
  cp -R "${repository_root}/cn" "${repository_root}/en" "${repository_root}/org" "${root}/"
  printf '%s\n' "${root}"
}

replace_line() {
  local file="$1"
  local original="$2"
  local replacement="$3"
  local temporary="${file}.tmp"
  sed "s|${original}|${replacement}|" "${file}" > "${temporary}"
  mv "${temporary}" "${file}"
}

expect_contract_failure() {
  local root="$1"
  local assertion_id="$2"
  local output="${root}/contract-output.txt"
  if "${orgize_bin}" contract workspace \
    --root "${root}" \
    --policy "${root}/org/workspace/philosophy.workspace.v1.org" \
    --org-contract-registry "${root}/org/contracts/philosophy.v1.org" \
    >"${output}" 2>&1; then
    echo "philosophy contract negative test: mutation unexpectedly passed" >&2
    exit 1
  fi
  if ! grep -Fq "${assertion_id}" "${output}"; then
    echo "philosophy contract negative test: expected ${assertion_id} failure" >&2
    sed -n '1,120p' "${output}" >&2
    exit 1
  fi
}

kind_root="$(make_fixture wrong-kind)"
kind_document="${kind_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${kind_document}" '^:DOC_KIND: charter$' ':DOC_KIND: reflection'
expect_contract_failure "${kind_root}" charter.cn.has-document-kind

source_root="$(make_fixture empty-source-author)"
source_document="${source_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_document}" '^:SOURCE_AUTHOR:.*$' ':SOURCE_AUTHOR: '
expect_contract_failure "${source_root}" source-note.cn.has-source-author

source_kind_root="$(make_fixture invalid-source-kind)"
source_kind_document="${source_kind_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_kind_document}" '^:SOURCE_KIND: PRIMARY$' ':SOURCE_KIND: INTERPRETATION'
expect_contract_failure "${source_kind_root}" source-note.cn.has-source-kind

echo "philosophy contract negative test: passed"
