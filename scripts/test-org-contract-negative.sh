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

document_id_root="$(make_fixture empty-document-id)"
document_id_file="${document_id_root}/cn/30-reflections/30.10-knowledge-action-in-agent-age.org"
replace_line "${document_id_file}" '^:DOC_ID:.*$' ':DOC_ID: '
expect_contract_failure "${document_id_root}" document.has-doc-id

source_root="$(make_fixture empty-source-author)"
source_document="${source_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_document}" '^:SOURCE_AUTHOR:.*$' ':SOURCE_AUTHOR: '
expect_contract_failure "${source_root}" source-note.cn.has-source-author

source_kind_root="$(make_fixture invalid-source-kind)"
source_kind_document="${source_kind_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_kind_document}" '^:SOURCE_KIND: PRIMARY$' ':SOURCE_KIND: INTERPRETATION'
expect_contract_failure "${source_kind_root}" source-note.cn.has-source-kind

engineering_locator_root="$(make_fixture missing-engineering-locator)"
engineering_locator_file="${engineering_locator_root}/cn/40-sources/40.50-agent-systems-state-authority.org"
replace_line "${engineering_locator_file}" '^:SOURCE_KIND:.*$' ':SOURCE_KIND: ENGINEERING_EVIDENCE'
replace_line "${engineering_locator_file}" '^:SOURCE_REPOSITORIES:.*$' ':SOURCE_REPOSITORIES: philosophy'
replace_line "${engineering_locator_file}" '^:SOURCE_REVISIONS:.*$' ':SOURCE_REVISIONS: evidence-pending'
replace_line "${engineering_locator_file}" '^:SOURCE_PATHS:.*$' ':SOURCE_PATHS: org/contracts/philosophy.v1.org'
replace_line "${engineering_locator_file}" '^:OBSERVATION_DATE:.*$' ':OBSERVATION_DATE: 2026-09-20'
expect_contract_failure "${engineering_locator_root}" source-note.cn.has-engineering-revisions

synthesis_root="$(make_fixture missing-synthesis-constituents)"
synthesis_file="${synthesis_root}/cn/40-sources/40.30-scientific-method-evidence.org"
replace_line "${synthesis_file}" '^:CONSTITUENT_SOURCES:.*$' ':CONSTITUENT_SOURCES: evidence-pending'
expect_contract_failure "${synthesis_root}" source-note.cn.has-synthesis-constituent-sources

source_pair_root="$(make_fixture mismatched-source-id)"
source_pair_file="${source_pair_root}/en/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_pair_file}" '^:SOURCE_ID:.*$' ':SOURCE_ID: source.unrelated'
expect_contract_failure "${source_pair_root}" 'must have equal document property SOURCE_ID'

locator_pair_root="$(make_fixture mismatched-source-paths)"
locator_pair_file="${locator_pair_root}/en/40-sources/40.50-agent-systems-state-authority.org"
replace_line "${locator_pair_file}" '^:SOURCE_PATHS:.*$' ':SOURCE_PATHS: unrelated/path'
expect_contract_failure "${locator_pair_root}" 'must have equal document property SOURCE_PATHS'

governance_pair_root="$(make_fixture mismatched-governance-id)"
governance_pair_file="${governance_pair_root}/en/90-governance/90.00-authoring-and-admission.org"
replace_line "${governance_pair_file}" '^:GOVERNANCE_ID:.*$' ':GOVERNANCE_ID: philosophy.other-governance.v1'
expect_contract_failure "${governance_pair_root}" 'must have equal document property GOVERNANCE_ID'

principle_ref_root="$(make_fixture empty-principle-ref)"
principle_ref_file="${principle_ref_root}/cn/20-engineering/20.10-cross-repository-realization-map.org"
replace_line "${principle_ref_file}" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: '
expect_contract_failure "${principle_ref_root}" engineering-map.cn.has-principle-ref

pair_ref_root="$(make_fixture mismatched-principle-ref)"
pair_ref_file="${pair_ref_root}/en/20-engineering/20.10-cross-repository-realization-map.org"
replace_line "${pair_ref_file}" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: PHIL-OTHER-001'
expect_contract_failure "${pair_ref_root}" 'must have equal document property PRINCIPLE_REF'

echo "philosophy contract negative test: passed"
