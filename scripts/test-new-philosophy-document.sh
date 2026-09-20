#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/philosophy-scaffolder.XXXXXX")"
trap 'rm -rf "${fixture_root}"' EXIT

mkdir -p \
  "${fixture_root}/scripts" \
  "${fixture_root}/org/templates" \
  "${fixture_root}/cn/10-charter" \
  "${fixture_root}/en/10-charter" \
  "${fixture_root}/cn/20-engineering" \
  "${fixture_root}/en/20-engineering" \
  "${fixture_root}/cn/40-sources" \
  "${fixture_root}/en/40-sources"
cp "${repository_root}/scripts/new-philosophy-document.sh" "${fixture_root}/scripts/"
cp "${repository_root}"/org/templates/philosophy.{charter,engineering-map,source-note}.{cn,en}.v1.org \
  "${fixture_root}/org/templates/"

scaffolder="${fixture_root}/scripts/new-philosophy-document.sh"

expect_failure() {
  if "$@" >/dev/null 2>&1; then
    echo "philosophy scaffolder test: command unexpectedly succeeded: $*" >&2
    exit 1
  fi
}

assert_property() {
  local file="$1"
  local property="$2"
  local expected="$3"
  if ! grep -Fqx ":${property}: ${expected}" "${file}"; then
    echo "philosophy scaffolder test: ${file} lacks ${property}=${expected}" >&2
    exit 1
  fi
}

common=(env TITLE_ZH=测试 TITLE_EN=Test)

expect_failure "${common[@]}" "${scaffolder}" source-note 40.90-missing.org SRC-MISSING
expect_failure env TITLE_ZH=测试 TITLE_EN=Test \
  SOURCE_AUTHOR=Author SOURCE_WORK=Work SOURCE_LANGUAGE=zh SOURCE_EDITION=edition-1 \
  "${scaffolder}" source-note 40.90-missing-date.org SRC-MISSING-DATE
expect_failure env TITLE_ZH=测试 TITLE_EN=Test \
  SOURCE_AUTHOR=Author SOURCE_WORK=Work SOURCE_LANGUAGE=zh \
  SOURCE_KIND=INTERPRETATION \
  "${scaffolder}" source-note 40.91-invalid-kind.org SRC-INVALID

env TITLE_ZH=来源 TITLE_EN=Source \
  SOURCE_AUTHOR='Source Author' SOURCE_WORK='Source Work' \
  SOURCE_LANGUAGE=classical-zh SOURCE_KIND=PRIMARY SOURCE_EDITION=juan-1 SOURCE_DATE=1527 \
  "${scaffolder}" source-note 40.92-source.org SRC-001 >/dev/null
for locale in cn en; do
  source_file="${fixture_root}/${locale}/40-sources/40.92-source.org"
  assert_property "${source_file}" SOURCE_AUTHOR 'Source Author'
  assert_property "${source_file}" SOURCE_WORK 'Source Work'
  assert_property "${source_file}" SOURCE_LANGUAGE classical-zh
  assert_property "${source_file}" SOURCE_KIND PRIMARY
  assert_property "${source_file}" SOURCE_EDITION juan-1
  assert_property "${source_file}" SOURCE_DATE 1527
  assert_property "${source_file}" SOURCE_REPOSITORIES not-applicable
done

expect_failure env TITLE_ZH=工程 TITLE_EN=Engineering \
  SOURCE_AUTHOR=Tao3k SOURCE_WORK=Observation SOURCE_LANGUAGE=en \
  SOURCE_KIND=ENGINEERING_EVIDENCE SOURCE_EDITION=workspace-v1 SOURCE_DATE=2026-09-20 \
  "${scaffolder}" source-note 40.93-missing-locators.org ENG-MISSING
env TITLE_ZH=工程 TITLE_EN=Engineering \
  SOURCE_AUTHOR=Tao3k SOURCE_WORK=Observation SOURCE_LANGUAGE=en \
  SOURCE_KIND=ENGINEERING_EVIDENCE SOURCE_EDITION=workspace-v1 SOURCE_DATE=2026-09-20 \
  SOURCE_REPOSITORIES='orgize philosophy' SOURCE_REVISIONS='abc123 def456' \
  SOURCE_PATHS='rfc/001 src/lib.rs' OBSERVATION_DATE=2026-09-20 \
  "${scaffolder}" source-note 40.94-engineering.org ENG-001 >/dev/null
for locale in cn en; do
  engineering_file="${fixture_root}/${locale}/40-sources/40.94-engineering.org"
  assert_property "${engineering_file}" SOURCE_REPOSITORIES 'orgize philosophy'
  assert_property "${engineering_file}" SOURCE_REVISIONS 'abc123 def456'
  assert_property "${engineering_file}" SOURCE_PATHS 'rfc/001 src/lib.rs'
  assert_property "${engineering_file}" OBSERVATION_DATE 2026-09-20
done

expect_failure "${common[@]}" "${scaffolder}" charter 10.90-missing.org PHIL-MISSING
env TITLE_ZH=原则 TITLE_EN=Principle \
  PRINCIPLE_REF=PHIL-NEW-001 REFINES='PHIL-002 PHIL-005' \
  "${scaffolder}" charter 10.91-principle.org PHIL-NEW >/dev/null
for locale in cn en; do
  charter_file="${fixture_root}/${locale}/10-charter/10.91-principle.org"
  assert_property "${charter_file}" PRINCIPLE_ID PHIL-NEW-001
  assert_property "${charter_file}" REFINES 'PHIL-002 PHIL-005'
done

expect_failure "${common[@]}" "${scaffolder}" engineering-map 20.90-missing.org MAP-MISSING
env TITLE_ZH=映射 TITLE_EN=Map PRINCIPLE_REF=PHIL-AUTH-001 \
  "${scaffolder}" engineering-map 20.91-map.org MAP-001 >/dev/null
for locale in cn en; do
  assert_property "${fixture_root}/${locale}/20-engineering/20.91-map.org" \
    PRINCIPLE_REF PHIL-AUTH-001
done

if rg -n '<[A-Z_]+>|PHIL-ROOT-ID' "${fixture_root}/cn" "${fixture_root}/en"; then
  echo "philosophy scaffolder test: generated documents contain unresolved placeholders" >&2
  exit 1
fi

echo "philosophy scaffolder test: passed"
