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

insert_line_after() {
  local file="$1"
  local pattern="$2"
  local line="$3"
  local temporary="${file}.tmp"
  awk -v pattern="${pattern}" -v line="${line}" '{ print } $0 ~ pattern { print line }' "${file}" > "${temporary}"
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

child_masked_kind_root="$(make_fixture child-masked-charter-kind)"
for locale in cn en; do
  child_masked_kind_file="${child_masked_kind_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  replace_line "${child_masked_kind_file}" '^:DOC_KIND: charter$' ':DOC_KIND: reflection'
  printf '\n* Invalid child mask\n:PROPERTIES:\n:DOC_KIND: charter\n:END:\n' >> "${child_masked_kind_file}"
done
expect_contract_failure "${child_masked_kind_root}" charter.cn.has-document-kind

child_masked_topology_root="$(make_fixture child-masked-topology-metadata)"
for locale in cn en; do
  child_masked_topology_file="${child_masked_topology_root}/${locale}/00-topology/00.00-repository-topology.org"
  replace_line "${child_masked_topology_file}" '^:TOPOLOGY_ID:.*$' ':TOPOLOGY_ID: '
  replace_line "${child_masked_topology_file}" '^:PATH_POLICY:.*$' ':PATH_POLICY: open-world'
  replace_line "${child_masked_topology_file}" '^:NAVIGATION_ROOT:.*$' ':NAVIGATION_ROOT: '
  printf '\n* Invalid child mask\n:PROPERTIES:\n:TOPOLOGY_ID: child.topology\n:PATH_POLICY: closed-world\n:NAVIGATION_ROOT: child-root\n:END:\n' >> "${child_masked_topology_file}"
done
expect_contract_failure "${child_masked_topology_root}" topology.has-id

child_masked_repository_index_root="$(make_fixture child-masked-repository-index-metadata)"
child_masked_repository_index_file="${child_masked_repository_index_root}/README.org"
replace_line "${child_masked_repository_index_file}" '^:TOPOLOGY_ID:.*$' ':TOPOLOGY_ID: '
replace_line "${child_masked_repository_index_file}" '^:PATH_POLICY:.*$' ':PATH_POLICY: open-world'
replace_line "${child_masked_repository_index_file}" '^:NAVIGATION_ROOT:.*$' ':NAVIGATION_ROOT: nowhere'
printf '\n* Invalid child mask\n:PROPERTIES:\n:TOPOLOGY_ID: child.repository\n:PATH_POLICY: closed-world\n:NAVIGATION_ROOT: cn/README.org en/README.org\n:END:\n' >> "${child_masked_repository_index_file}"
expect_contract_failure "${child_masked_repository_index_root}" repository-index.has-topology-id
expect_contract_failure "${child_masked_repository_index_root}" repository-index.has-path-policy
expect_contract_failure "${child_masked_repository_index_root}" repository-index.has-navigation-root

missing_en_route_root="$(make_fixture missing-en-index-route)"
replace_line "${missing_en_route_root}/README.org" \
  '\[\[file:en/README.org\]\[en/README.org\]\]' \
  '[[file:cn/README.org][cn/README.org]]'
expect_contract_failure "${missing_en_route_root}" repository-index.has-en-index-link

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

empty_cn_engineering_property_root="$(make_fixture empty-cn-engineering-property)"
empty_cn_engineering_property_file="${empty_cn_engineering_property_root}/cn/20-engineering/20.00-knowledge-action-map.org"
replace_line "${empty_cn_engineering_property_file}" \
  '^[|] 知 [|].*$' '| 知 || 模型自信 | ASP / MRR |'
replace_line "${empty_cn_engineering_property_file}" \
  '^[|] 辨 [|].*$' '| 辨 || plausible completion | MRR |'
replace_line "${empty_cn_engineering_property_file}" \
  '^[|] 证 [|].*$' '| 证 || 语言流畅性 | Aitia / POO Flow verifier handoff |'
replace_line "${empty_cn_engineering_property_file}" \
  '^[|] 行 [|].*$' '| 行 || 工具可用性 | ASP / Marlin |'
replace_line "${empty_cn_engineering_property_file}" \
  '^[|] 验 [|].*$' '| 验 || 调用返回码 | POO Flow / MRR |'
expect_contract_failure "${empty_cn_engineering_property_root}" engineering-map.cn.has-normative-requirements

empty_en_current_realization_root="$(make_fixture empty-en-current-realization)"
empty_en_current_realization_file="${empty_en_current_realization_root}/en/20-engineering/20.00-knowledge-action-map.org"
replace_line "${empty_en_current_realization_file}" \
  '^[|] Contract admission [|].*$' '| Contract admission || Implemented | =just check= |'
replace_line "${empty_en_current_realization_file}" \
  '^[|] Workspace topology [|].*$' '| Workspace topology || Implemented | =org/workspace/philosophy.workspace.v1.org= |'
replace_line "${empty_en_current_realization_file}" \
  '^[|] Agent scenario gate [|].*$' '| Agent scenario gate || Implemented | Orgize workspace scale scenario |'
replace_line "${empty_en_current_realization_file}" \
  '^[|] Downstream philosophy mapping [|].*$' '| Downstream philosophy mapping || Requires independent proof | per-project receipts |'
expect_contract_failure "${empty_en_current_realization_root}" engineering-map.en.has-current-realization

document_id_root="$(make_fixture empty-document-id)"
document_id_file="${document_id_root}/cn/30-reflections/30.10-knowledge-action-in-agent-age.org"
replace_line "${document_id_file}" '^:DOC_ID:.*$' ':DOC_ID: '
expect_contract_failure "${document_id_root}" document.has-doc-id

child_masked_doc_status_root="$(make_fixture child-masked-doc-status)"
for locale in cn en; do
  child_masked_doc_status_file="${child_masked_doc_status_root}/${locale}/30-reflections/30.10-knowledge-action-in-agent-age.org"
  replace_line "${child_masked_doc_status_file}" '^:DOC_STATUS:.*$' ':DOC_STATUS: withdrawn'
  printf '\n* Invalid child mask\n:PROPERTIES:\n:DOC_STATUS: accepted\n:END:\n' >> "${child_masked_doc_status_file}"
done
expect_contract_failure "${child_masked_doc_status_root}" document.has-doc-status

duplicate_principle_root="$(make_fixture duplicate-principle-identity)"
for locale in cn en; do
  replace_line "${duplicate_principle_root}/${locale}/10-charter/10.00-tao3k-charter.org" \
    '^:PRINCIPLE_ID: PHIL-007$' ':PRINCIPLE_ID: PHIL-001'
done
expect_contract_failure "${duplicate_principle_root}" 'must have identical unique paired node identities in PRINCIPLE_ID'

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
for locale in cn en; do
  source_kind_document="${source_kind_root}/${locale}/40-sources/40.10-wang-yangming-knowledge-action.org"
  replace_line "${source_kind_document}" '^:SOURCE_KIND: PRIMARY$' ':SOURCE_KIND: INTERPRETATION'
done
expect_contract_failure "${source_kind_root}" source-note.cn.has-source-kind

masked_source_kind_root="$(make_fixture child-masked-source-kind)"
for locale in cn en; do
  masked_source_kind_file="${masked_source_kind_root}/${locale}/40-sources/40.10-wang-yangming-knowledge-action.org"
  replace_line "${masked_source_kind_file}" '^:SOURCE_KIND: PRIMARY$' ':SOURCE_KIND: INTERPRETATION'
  printf '\n* Masking child\n:PROPERTIES:\n:SOURCE_KIND: PRIMARY\n:END:\n' >>"${masked_source_kind_file}"
done
expect_contract_failure "${masked_source_kind_root}" source-note.cn.has-source-kind

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
expect_contract_failure "${unresolved_ref_root}" "document property PRINCIPLE_REF reference \`PHIL-MISSING-001\` does not resolve to node identity PRINCIPLE_ID"

unresolved_refines_root="$(make_fixture unresolved-refines)"
unresolved_refines_file="${unresolved_refines_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${unresolved_refines_file}" '^:REFINES:.*$' ':REFINES: PHIL-MISSING-001'
replace_line "${unresolved_refines_root}/en/10-charter/10.10-epistemology-and-uncertainty.org" '^:REFINES:.*$' ':REFINES: PHIL-MISSING-001'
expect_contract_failure "${unresolved_refines_root}" "node property REFINES reference \`PHIL-MISSING-001\` does not resolve to node identity PRINCIPLE_ID"

mixed_refines_root="$(make_fixture mixed-refines-sentinel)"
for locale in cn en; do
  replace_line "${mixed_refines_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:REFINES:.*$' ':REFINES: none PHIL-KNOW-ACT-001'
done
expect_contract_failure "${mixed_refines_root}" 'node property REFINES must not mix allowed sentinel values with identity references'

self_refines_root="$(make_fixture self-refines)"
for locale in cn en; do
  replace_line "${self_refines_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:REFINES:.*$' ':REFINES: PHIL-EPI-001'
done
expect_contract_failure "${self_refines_root}" "node \`PHIL-EPI-001\` property REFINES must not reference its own identity"

refinement_cycle_root="$(make_fixture refinement-cycle)"
for locale in cn en; do
  replace_line "${refinement_cycle_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:REFINES:.*$' ':REFINES: PHIL-TEMP-001'
  replace_line "${refinement_cycle_root}/${locale}/10-charter/10.20-temporality-and-causality.org" '^:REFINES:.*$' ':REFINES: PHIL-EPI-001'
done
expect_contract_failure "${refinement_cycle_root}" 'node property REFINES must be acyclic; cycle: PHIL-EPI-001 -> PHIL-TEMP-001 -> PHIL-EPI-001'

superseded_without_successor_root="$(make_fixture superseded-without-successor)"
for locale in cn en; do
  replace_line "${superseded_without_successor_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:PRINCIPLE_STATUS:.*$' ':PRINCIPLE_STATUS: superseded'
done
expect_contract_failure "${superseded_without_successor_root}" charter.cn.every-principle-has-complete-metadata

accepted_successor_root="$(make_fixture accepted-successor)"
for locale in cn en; do
  epistemology_file="${accepted_successor_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  temporality_file="${accepted_successor_root}/${locale}/10-charter/10.20-temporality-and-causality.org"
  replace_line "${epistemology_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-TEMP-001'
  replace_line "${temporality_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-EPI-001'
done
expect_contract_failure "${accepted_successor_root}" charter.cn.every-principle-has-complete-metadata

draft_successor_root="$(make_fixture draft-successor)"
for locale in cn en; do
  epistemology_file="${draft_successor_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  temporality_file="${draft_successor_root}/${locale}/10-charter/10.20-temporality-and-causality.org"
  replace_line "${epistemology_file}" '^:PRINCIPLE_STATUS:.*$' ':PRINCIPLE_STATUS: superseded'
  replace_line "${epistemology_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-TEMP-001'
  replace_line "${temporality_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-EPI-001'
done
expect_contract_failure "${draft_successor_root}" \
  'target property PRINCIPLE_STATUS must be one of accepted, superseded'

for invalid_revision in latest -1 0 +1; do
  revision_root="$(make_fixture "invalid-revision-${invalid_revision//+/-plus-}")"
  for locale in cn en; do
    replace_line "${revision_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:REVISION:.*$' ":REVISION: ${invalid_revision}"
  done
  expect_contract_failure "${revision_root}" charter.cn.every-principle-has-complete-metadata
done

self_supersession_root="$(make_fixture self-supersession)"
for locale in cn en; do
  self_supersession_file="${self_supersession_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  replace_line "${self_supersession_file}" '^:PRINCIPLE_STATUS:.*$' ':PRINCIPLE_STATUS: superseded'
  replace_line "${self_supersession_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-EPI-001'
  replace_line "${self_supersession_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-EPI-001'
done
expect_contract_failure "${self_supersession_root}" "node \`PHIL-EPI-001\` property SUPERSEDES must not reference its own identity"

mixed_supersession_root="$(make_fixture mixed-supersession-sentinel)"
for locale in cn en; do
  mixed_supersession_file="${mixed_supersession_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  replace_line "${mixed_supersession_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: none PHIL-KNOW-ACT-001'
  replace_line "${mixed_supersession_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: none PHIL-TEMP-001'
done
expect_contract_failure "${mixed_supersession_root}" 'node property SUPERSEDES must not mix allowed sentinel values with identity references'
expect_contract_failure "${mixed_supersession_root}" 'node property SUPERSEDED_BY must not mix allowed sentinel values with identity references'

supersession_cycle_root="$(make_fixture supersession-cycle)"
for locale in cn en; do
  epistemology_file="${supersession_cycle_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org"
  temporality_file="${supersession_cycle_root}/${locale}/10-charter/10.20-temporality-and-causality.org"
  replace_line "${epistemology_file}" '^:PRINCIPLE_STATUS:.*$' ':PRINCIPLE_STATUS: superseded'
  replace_line "${epistemology_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-TEMP-001'
  replace_line "${epistemology_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-TEMP-001'
  replace_line "${temporality_file}" '^:PRINCIPLE_STATUS:.*$' ':PRINCIPLE_STATUS: superseded'
  replace_line "${temporality_file}" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-EPI-001'
  replace_line "${temporality_file}" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-EPI-001'
done
expect_contract_failure "${supersession_cycle_root}" 'must be acyclic; cycle: PHIL-EPI-001 -> PHIL-TEMP-001 -> PHIL-EPI-001'

unresolved_supersedes_root="$(make_fixture unresolved-supersedes)"
for locale in cn en; do
  replace_line "${unresolved_supersedes_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-MISSING-001'
done
expect_contract_failure "${unresolved_supersedes_root}" "node property SUPERSEDES reference \`PHIL-MISSING-001\` does not resolve to node identity PRINCIPLE_ID"

unresolved_superseded_by_root="$(make_fixture unresolved-superseded-by)"
for locale in cn en; do
  replace_line "${unresolved_superseded_by_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:SUPERSEDED_BY:.*$' ':SUPERSEDED_BY: PHIL-MISSING-001'
done
expect_contract_failure "${unresolved_superseded_by_root}" "node property SUPERSEDED_BY reference \`PHIL-MISSING-001\` does not resolve to node identity PRINCIPLE_ID"

nonreciprocal_supersedes_root="$(make_fixture nonreciprocal-supersedes)"
for locale in cn en; do
  replace_line "${nonreciprocal_supersedes_root}/${locale}/10-charter/10.10-epistemology-and-uncertainty.org" '^:SUPERSEDES:.*$' ':SUPERSEDES: PHIL-001'
done
expect_contract_failure "${nonreciprocal_supersedes_root}" "property SUPERSEDES reference \`PHIL-001\` must be reciprocated by target property SUPERSEDED_BY"

interpretation_status_root="$(make_fixture invalid-interpretation-status)"
for locale in cn en; do
  replace_line "${interpretation_status_root}/${locale}/40-sources/40.10-wang-yangming-knowledge-action.org" '^:INTERPRETATION_STATUS:.*$' ':INTERPRETATION_STATUS: COMPLETE'
done
expect_contract_failure "${interpretation_status_root}" source-note.cn.has-interpretation-status

child_masked_status_root="$(make_fixture child-masked-interpretation-status)"
for locale in cn en; do
  child_masked_status_file="${child_masked_status_root}/${locale}/40-sources/40.10-wang-yangming-knowledge-action.org"
  replace_line "${child_masked_status_file}" '^:INTERPRETATION_STATUS:.*$' ':INTERPRETATION_STATUS: COMPLETE'
  printf '\n* Invalid child mask\n:PROPERTIES:\n:INTERPRETATION_STATUS: DIRECT\n:END:\n' >> "${child_masked_status_file}"
done
expect_contract_failure "${child_masked_status_root}" source-note.cn.has-interpretation-status

trace_root="$(make_fixture empty-trace-row)"
trace_file="${trace_root}/cn/10-charter/10.10-epistemology-and-uncertainty.org"
replace_line "${trace_file}" '^[|] PHIL-EPI-001 .*$' '| PHIL-EPI-001 | | | |'
expect_contract_failure "${trace_root}" charter.cn.has-trace-table

trace_coverage_root="$(make_fixture missing-trace-principle)"
trace_coverage_file="${trace_coverage_root}/cn/10-charter/10.00-tao3k-charter.org"
replace_line "${trace_coverage_file}" '^[|] PHIL-007 .*$' '| PHIL-001 | duplicate trace | duplicate owner |'
expect_contract_failure "${trace_coverage_root}" charter.cn.trace-covers-every-principle

trace_engineering_root="$(make_fixture missing-trace-engineering)"
trace_engineering_file="${trace_engineering_root}/cn/10-charter/10.00-tao3k-charter.org"
replace_line "${trace_engineering_file}" \
  '^[|] PHIL-007 [|].*$' '| PHIL-007 || POO Flow / MRR |'
expect_contract_failure "${trace_engineering_root}" charter.cn.trace-engineering-complete

compensated_trace_root="$(make_fixture compensated-trace-engineering)"
compensated_trace_file="${compensated_trace_root}/cn/10-charter/10.00-tao3k-charter.org"
replace_line "${compensated_trace_file}" \
  '^[|] PHIL-007 [|].*$' '| PHIL-007 || POO Flow / MRR |'
insert_line_after "${compensated_trace_file}" \
  '^[|][-]+[+][-]+[+][-]+[|]$' '| PHIL-001 | compensating direction | compensating owner |'
expect_contract_failure "${compensated_trace_root}" charter.cn.trace-engineering-complete

trace_owner_root="$(make_fixture missing-trace-owner)"
trace_owner_file="${trace_owner_root}/en/10-charter/10.00-tao3k-charter.org"
replace_line "${trace_owner_file}" \
  '^[|] PHIL-007 [|].*$' '| PHIL-007 | receipt, observation, invalidation ||'
expect_contract_failure "${trace_owner_root}" charter.en.trace-owner-complete

echo "philosophy contract negative test: passed"
