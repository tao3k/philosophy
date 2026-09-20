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
  sed "s#${original}#${replacement}#" "${file}" > "${temporary}"
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

empty_cn_section_root="$(make_fixture empty-cn-counterarguments)"
empty_cn_section_file="${empty_cn_section_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${empty_cn_section_file}" \
  '^低风险默认值和明确封闭世界仍可使用，但必须声明适用边界，不能冒充普遍事实。$' ''
expect_contract_failure "${empty_cn_section_root}" charter.cn.has-counterarguments

empty_en_section_root="$(make_fixture empty-en-counterarguments)"
empty_en_section_file="${empty_en_section_root}/en/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${empty_en_section_file}" \
  '^Low-risk defaults and explicit closed worlds remain useful, but their scope must be declared rather than presented as universal fact.$' ''
expect_contract_failure "${empty_en_section_root}" charter.en.has-counterarguments

empty_cn_reflection_root="$(make_fixture empty-cn-reflection-argument)"
empty_cn_reflection_file="${empty_cn_reflection_root}/cn/30-reflections/30.10-knowledge-action-in-agent-age.org"
replace_line "${empty_cn_reflection_file}" \
  '^行动必须消费有来源的知识、显式判断与授权；结果必须以 receipt 和观察重新进入知识层。闭环不是从模型置信度直接跳到执行。$' ''
expect_contract_failure "${empty_cn_reflection_root}" reflection.cn.has-argument

empty_en_reflection_root="$(make_fixture empty-en-reflection-argument)"
empty_en_reflection_file="${empty_en_reflection_root}/en/30-reflections/30.10-knowledge-action-in-agent-age.org"
replace_line "${empty_en_reflection_file}" \
  '^Action must consume sourced knowledge, explicit judgment, and authorization; outcomes must return through receipts and observation. Closure is not a jump from model confidence to execution.$' ''
expect_contract_failure "${empty_en_reflection_root}" reflection.en.has-argument

empty_cn_engineering_root="$(make_fixture empty-cn-engineering-review)"
empty_cn_engineering_file="${empty_cn_engineering_root}/cn/20-engineering/20.00-knowledge-action-map.org"
replace_line "${empty_cn_engineering_file}" \
  '^设计审查必须回答：知道什么、仍未知什么、推理关系是什么、需要何种证成、谁有权、$' ''
replace_line "${empty_cn_engineering_file}" \
  '^世界将如何变化、结果如何复验，以及结果含混时如何处理。$' ''
expect_contract_failure "${empty_cn_engineering_root}" engineering-map.cn.has-review

empty_en_engineering_root="$(make_fixture empty-en-engineering-review)"
empty_en_engineering_file="${empty_en_engineering_root}/en/20-engineering/20.00-knowledge-action-map.org"
replace_line "${empty_en_engineering_file}" \
  '^A design review asks what is known, what remains unknown, what relations support$' ''
replace_line "${empty_en_engineering_file}" \
  '^the judgment, what assurance is required, who has authority, how the world will$' ''
replace_line "${empty_en_engineering_file}" \
  '^change, how the outcome returns as knowledge, and what happens when it is ambiguous.$' ''
expect_contract_failure "${empty_en_engineering_root}" engineering-map.en.has-review

document_id_root="$(make_fixture empty-document-id)"
document_id_file="${document_id_root}/cn/30-reflections/30.10-knowledge-action-in-agent-age.org"
replace_line "${document_id_file}" '^:DOC_ID:.*$' ':DOC_ID: '
expect_contract_failure "${document_id_root}" document.has-doc-id

source_root="$(make_fixture empty-source-author)"
source_document="${source_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_document}" '^:SOURCE_AUTHOR:.*$' ':SOURCE_AUTHOR: '
expect_contract_failure "${source_root}" source-note.cn.has-source-author

empty_cn_source_context_root="$(make_fixture empty-cn-source-context)"
empty_cn_source_context_file="${empty_cn_source_context_root}/cn/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${empty_cn_source_context_file}" \
  '^“知”不是模型中任意可用的命题缓存，“行”也不是工具调用。原语境关注道德认识、意向与实践不可被方便地割裂。$' ''
expect_contract_failure "${empty_cn_source_context_root}" source-note.cn.has-context

empty_en_source_context_root="$(make_fixture empty-en-source-context)"
empty_en_source_context_file="${empty_en_source_context_root}/en/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${empty_en_source_context_file}" \
  '^Knowledge is not an arbitrary proposition cache, and action is not a tool call. The historical concern is that moral understanding, intention, and practice cannot be separated for convenience.$' ''
expect_contract_failure "${empty_en_source_context_root}" source-note.en.has-context

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

source_author_pair_root="$(make_fixture mismatched-source-author)"
source_author_pair_file="${source_author_pair_root}/en/40-sources/40.10-wang-yangming-knowledge-action.org"
replace_line "${source_author_pair_file}" '^:SOURCE_AUTHOR:.*$' ':SOURCE_AUTHOR: unrelated author'
expect_contract_failure "${source_author_pair_root}" 'must have equal document property SOURCE_AUTHOR'

locator_pair_root="$(make_fixture mismatched-source-paths)"
locator_pair_file="${locator_pair_root}/en/40-sources/40.50-agent-systems-state-authority.org"
replace_line "${locator_pair_file}" '^:SOURCE_PATHS:.*$' ':SOURCE_PATHS: unrelated/path'
expect_contract_failure "${locator_pair_root}" 'must have equal document property SOURCE_PATHS'

governance_pair_root="$(make_fixture mismatched-governance-id)"
governance_pair_file="${governance_pair_root}/en/90-governance/90.00-authoring-and-admission.org"
replace_line "${governance_pair_file}" '^:GOVERNANCE_ID:.*$' ':GOVERNANCE_ID: philosophy.other-governance.v1'
expect_contract_failure "${governance_pair_root}" 'must have equal document property GOVERNANCE_ID'

principle_kind_root="$(make_fixture invalid-foundational-refines)"
principle_kind_file="${principle_kind_root}/cn/10-charter/10.00-tao3k-charter.org"
replace_line "${principle_kind_file}" '^:REFINES: none$' ':REFINES: PHIL-001'
expect_contract_failure "${principle_kind_root}" charter.cn.every-principle-has-complete-metadata

principle_ref_root="$(make_fixture empty-principle-ref)"
principle_ref_file="${principle_ref_root}/cn/20-engineering/20.10-cross-repository-realization-map.org"
replace_line "${principle_ref_file}" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: '
expect_contract_failure "${principle_ref_root}" engineering-map.cn.has-principle-ref

pair_ref_root="$(make_fixture mismatched-principle-ref)"
pair_ref_file="${pair_ref_root}/en/20-engineering/20.10-cross-repository-realization-map.org"
replace_line "${pair_ref_file}" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: PHIL-OTHER-001'
expect_contract_failure "${pair_ref_root}" 'must have equal document property PRINCIPLE_REF'

unresolved_ref_root="$(make_fixture unresolved-principle-ref)"
unresolved_ref_file="${unresolved_ref_root}/cn/20-engineering/20.10-cross-repository-realization-map.org"
replace_line "${unresolved_ref_file}" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: PHIL-MISSING-001'
replace_line "${unresolved_ref_root}/en/20-engineering/20.10-cross-repository-realization-map.org" '^:PRINCIPLE_REF:.*$' ':PRINCIPLE_REF: PHIL-MISSING-001'
expect_contract_failure "${unresolved_ref_root}" 'document property PRINCIPLE_REF reference `PHIL-MISSING-001` does not resolve to node identity PRINCIPLE_ID'

unresolved_refines_root="$(make_fixture unresolved-refines)"
unresolved_refines_file="${unresolved_refines_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${unresolved_refines_file}" '^:REFINES:.*$' ':REFINES: PHIL-MISSING-001'
replace_line "${unresolved_refines_root}/en/10-charter/10.10-epistemology-and-uncertainty.org" '^:REFINES:.*$' ':REFINES: PHIL-MISSING-001'
expect_contract_failure "${unresolved_refines_root}" 'node property REFINES reference `PHIL-MISSING-001` does not resolve to node identity PRINCIPLE_ID'

trace_root="$(make_fixture empty-trace-row)"
trace_file="${trace_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${trace_file}" '^[|] PHIL-EPI-001 .*$' '| PHIL-EPI-001 | | | |'
expect_contract_failure "${trace_root}" charter.cn.has-trace-table

echo "philosophy contract negative test: passed"
