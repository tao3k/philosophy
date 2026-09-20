#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' repository-index topology charter engineering-map reflection source-note governance
  exit 0
fi

kind="${1:-}"
filename="${2:-}"
base_doc_id="${3:-}"
title_zh="${TITLE_ZH:-}"
title_en="${TITLE_EN:-}"
title="${TITLE:-}"
author="${AUTHOR:-Tao3k}"

if [ -z "${kind}" ] || [ -z "${filename}" ] || [ -z "${base_doc_id}" ]; then
  echo "usage: TITLE_ZH='...' TITLE_EN='...' just new <kind> <NN.name.org> <DOC_ID>" >&2
  exit 2
fi
if [ "${kind}" = repository-index ] && [ -z "${title}" ]; then
  echo "philosophy: TITLE is required for repository-index" >&2
  exit 2
fi
if [ "${kind}" != repository-index ] && { [ -z "${title_zh}" ] || [ -z "${title_en}" ]; }; then
  echo "philosophy: TITLE_ZH and TITLE_EN are required" >&2
  exit 2
fi
case "${filename}" in
  *.org) ;;
  *) echo "philosophy: filename must end in .org" >&2; exit 2 ;;
esac
case "${filename}" in
  *[!A-Za-z0-9._-]*)
    echo "philosophy: filename may contain only letters, digits, dot, underscore, and hyphen" >&2
    exit 2
    ;;
esac

case "${kind}" in
  repository-index)
    subdir=""
    if [ "${filename}" != README.org ]; then
      echo "philosophy: repository-index must render to README.org" >&2
      exit 2
    fi
    ;;
  topology) subdir="00-topology" ;;
  charter) subdir="10-charter" ;;
  engineering-map) subdir="20-engineering" ;;
  reflection) subdir="30-reflections" ;;
  source-note) subdir="40-sources" ;;
  governance) subdir="90-governance" ;;
  *) echo "philosophy: unsupported kind '${kind}'; run 'just kinds'" >&2; exit 2 ;;
esac

if [ "${kind}" = repository-index ]; then
  singleton_destination="${repository_root}/${filename}"
else
  cn_destination="${repository_root}/cn/${subdir}/${filename}"
  en_destination="${repository_root}/en/${subdir}/${filename}"
fi

semantic_id="${SEMANTIC_ID:-philosophy.${kind}.${filename%.org}}"
topology_id="${TOPOLOGY_ID:-${base_doc_id}}"
principle_ref="${PRINCIPLE_REF:-}"
principle_kind="${PRINCIPLE_KIND:-refinement}"
refines="${REFINES:-}"
source_id="${SOURCE_ID:-${base_doc_id}}"
source_kind="${SOURCE_KIND:-SYNTHESIS}"
interpretation_status="${INTERPRETATION_STATUS:-MODERNIZED}"
source_author="${SOURCE_AUTHOR:-}"
source_work="${SOURCE_WORK:-}"
source_language="${SOURCE_LANGUAGE:-}"
source_edition="${SOURCE_EDITION:-}"
source_date="${SOURCE_DATE:-}"
source_repositories="${SOURCE_REPOSITORIES:-not-applicable}"
source_revisions="${SOURCE_REVISIONS:-not-applicable}"
source_paths="${SOURCE_PATHS:-not-applicable}"
observation_date="${OBSERVATION_DATE:-not-applicable}"
constituent_sources="${CONSTITUENT_SOURCES:-not-applicable}"
today="$(date -u +%Y-%m-%d)"

require_input() {
  local name="$1"
  local value="$2"
  if [ -z "${value}" ]; then
    echo "philosophy: ${name} is required for ${kind}" >&2
    exit 2
  fi
}

reject_contract_sentinel() {
  local name="$1"
  local value="$2"
  case "${value}" in
    not-applicable|evidence-pending)
      echo "philosophy: ${name} cannot use contract sentinel '${value}' for ${kind}" >&2
      exit 2
      ;;
  esac
}

case "${kind}" in
  charter)
    require_input PRINCIPLE_REF "${principle_ref}"
    case "${principle_kind}" in
      foundational)
        if [ -n "${refines}" ] && [ "${refines}" != none ]; then
          echo "philosophy: foundational principles must use REFINES=none" >&2
          exit 2
        fi
        refines=none
        ;;
      refinement)
        require_input REFINES "${refines}"
        if [ "${refines}" = none ]; then
          echo "philosophy: refinement principles must name at least one REFINES target" >&2
          exit 2
        fi
        for target in ${refines}; do
          if [ "${target}" = none ]; then
            echo "philosophy: refinement principles must not mix REFINES=none with targets" >&2
            exit 2
          fi
          if [ "${target}" = "${principle_ref}" ]; then
            echo "philosophy: REFINES must not contain its own PRINCIPLE_REF" >&2
            exit 2
          fi
        done
        ;;
      *)
        echo "philosophy: PRINCIPLE_KIND must be foundational or refinement" >&2
        exit 2
        ;;
    esac
    ;;
  engineering-map)
    require_input PRINCIPLE_REF "${principle_ref}"
    ;;
  source-note)
    require_input SOURCE_AUTHOR "${source_author}"
    require_input SOURCE_WORK "${source_work}"
    require_input SOURCE_LANGUAGE "${source_language}"
    require_input SOURCE_EDITION "${source_edition}"
    require_input SOURCE_DATE "${source_date}"
    case "${source_kind}" in
      PRIMARY|SECONDARY|SYNTHESIS|ENGINEERING_EVIDENCE) ;;
      *)
        echo "philosophy: SOURCE_KIND must be PRIMARY, SECONDARY, SYNTHESIS, or ENGINEERING_EVIDENCE" >&2
        exit 2
        ;;
    esac
    case "${interpretation_status}" in
      DIRECT|ANALOGICAL|MODERNIZED) ;;
      *)
        echo "philosophy: INTERPRETATION_STATUS must be DIRECT, ANALOGICAL, or MODERNIZED" >&2
        exit 2
        ;;
    esac
    if [ "${source_kind}" = ENGINEERING_EVIDENCE ]; then
      source_repositories="${SOURCE_REPOSITORIES:-}"
      source_revisions="${SOURCE_REVISIONS:-}"
      source_paths="${SOURCE_PATHS:-}"
      observation_date="${OBSERVATION_DATE:-}"
      require_input SOURCE_REPOSITORIES "${source_repositories}"
      require_input SOURCE_REVISIONS "${source_revisions}"
      require_input SOURCE_PATHS "${source_paths}"
      require_input OBSERVATION_DATE "${observation_date}"
      reject_contract_sentinel SOURCE_REPOSITORIES "${source_repositories}"
      reject_contract_sentinel SOURCE_REVISIONS "${source_revisions}"
      reject_contract_sentinel SOURCE_PATHS "${source_paths}"
      reject_contract_sentinel OBSERVATION_DATE "${observation_date}"
    fi
    if [ "${source_kind}" = SYNTHESIS ]; then
      constituent_sources="${CONSTITUENT_SOURCES:-}"
      require_input CONSTITUENT_SOURCES "${constituent_sources}"
      reject_contract_sentinel CONSTITUENT_SOURCES "${constituent_sources}"
    fi
    ;;
esac

escape_sed_replacement() {
  printf '%s' "$1" | sed 's/[&|\\]/\\&/g'
}

render_template() {
  local locale="$1"
  local title="$2"
  local doc_id="$3"
  local counterpart="$4"
  local template="${repository_root}/org/templates/philosophy.${kind}.${locale}.v1.org"
  local temporary_file="$5"

  sed \
    -e "s|<TITLE>|$(escape_sed_replacement "${title}")|g" \
    -e "s|<AUTHOR>|$(escape_sed_replacement "${author}")|g" \
    -e "s|<DATE>|${today}|g" \
    -e "s|<DOC_ID>|$(escape_sed_replacement "${doc_id}")|g" \
    -e "s|<SEMANTIC_ID>|$(escape_sed_replacement "${semantic_id}")|g" \
    -e "s|<TOPOLOGY_ID>|$(escape_sed_replacement "${topology_id}")|g" \
    -e "s|<COUNTERPART>|$(escape_sed_replacement "${counterpart}")|g" \
    -e "s|<PRINCIPLE_REF>|$(escape_sed_replacement "${principle_ref}")|g" \
    -e "s|<PRINCIPLE_KIND>|$(escape_sed_replacement "${principle_kind}")|g" \
    -e "s|<REFINES>|$(escape_sed_replacement "${refines}")|g" \
    -e "s|<SOURCE_ID>|$(escape_sed_replacement "${source_id}")|g" \
    -e "s|<SOURCE_KIND>|$(escape_sed_replacement "${source_kind}")|g" \
    -e "s|<SOURCE_AUTHOR>|$(escape_sed_replacement "${source_author}")|g" \
    -e "s|<SOURCE_WORK>|$(escape_sed_replacement "${source_work}")|g" \
    -e "s|<SOURCE_EDITION>|$(escape_sed_replacement "${source_edition}")|g" \
    -e "s|<SOURCE_DATE>|$(escape_sed_replacement "${source_date}")|g" \
    -e "s|<SOURCE_LANGUAGE>|$(escape_sed_replacement "${source_language}")|g" \
    -e "s|<SOURCE_REPOSITORIES>|$(escape_sed_replacement "${source_repositories}")|g" \
    -e "s|<SOURCE_REVISIONS>|$(escape_sed_replacement "${source_revisions}")|g" \
    -e "s|<SOURCE_PATHS>|$(escape_sed_replacement "${source_paths}")|g" \
    -e "s|<OBSERVATION_DATE>|$(escape_sed_replacement "${observation_date}")|g" \
    -e "s|<CONSTITUENT_SOURCES>|$(escape_sed_replacement "${constituent_sources}")|g" \
    -e "s|<INTERPRETATION_STATUS>|$(escape_sed_replacement "${interpretation_status}")|g" \
    -e "s|<CLAIM_SCOPE>|$(escape_sed_replacement "${CLAIM_SCOPE:-${semantic_id}}")|g" \
    -e "s|<GOVERNANCE_ID>|$(escape_sed_replacement "${GOVERNANCE_ID:-${base_doc_id}}")|g" \
    -e "s|<LIFECYCLE_ID>|$(escape_sed_replacement "${LIFECYCLE_ID:-${base_doc_id}.lifecycle}")|g" \
    -e "s|<CUSTOM_ID>|$(escape_sed_replacement "${semantic_id}-${locale}")|g" \
    "${template}" > "${temporary_file}"
}

if [ "${kind}" = repository-index ]; then
  singleton_temporary=""
  trap '[ -z "${singleton_temporary}" ] || rm -f "${singleton_temporary}"' EXIT
  if [ -e "${singleton_destination}" ]; then
    echo "philosophy: refusing to overwrite existing README.org" >&2
    exit 1
  fi
  singleton_temporary="$(mktemp "${singleton_destination}.tmp.XXXXXX")"
  sed \
    -e "s|<TITLE>|$(escape_sed_replacement "${title}")|g" \
    -e "s|<AUTHOR>|$(escape_sed_replacement "${author}")|g" \
    -e "s|<DATE>|${today}|g" \
    -e "s|<DOC_ID>|$(escape_sed_replacement "${base_doc_id}")|g" \
    -e "s|<SEMANTIC_ID>|$(escape_sed_replacement "${semantic_id}")|g" \
    -e "s|<TOPOLOGY_ID>|$(escape_sed_replacement "${topology_id}")|g" \
    -e "s|<CUSTOM_ID>|$(escape_sed_replacement "${semantic_id}-index")|g" \
    "${repository_root}/org/templates/philosophy.repository-index.v1.org" \
    > "${singleton_temporary}"
  chmod 0644 "${singleton_temporary}"
  if ! mv -n "${singleton_temporary}" "${singleton_destination}" || [ -e "${singleton_temporary}" ]; then
    echo "philosophy: README.org appeared during publication" >&2
    exit 1
  fi
  singleton_temporary=""
  trap - EXIT
  echo "philosophy: created README.org"
  echo "philosophy: complete the repository index, then run 'just check'"
  exit 0
fi

cn_temporary=""
en_temporary=""
cn_published=""
cleanup() {
  [ -z "${cn_temporary}" ] || rm -f "${cn_temporary}"
  [ -z "${en_temporary}" ] || rm -f "${en_temporary}"
  [ -z "${cn_published}" ] || rm -f "${cn_published}"
}
trap cleanup EXIT

if [ -e "${cn_destination}" ] || [ -e "${en_destination}" ]; then
  echo "philosophy: refusing to overwrite an existing CN/EN document pair" >&2
  exit 1
fi

cn_temporary="$(mktemp "${cn_destination}.tmp.XXXXXX")"
en_temporary="$(mktemp "${en_destination}.tmp.XXXXXX")"

render_template cn "${title_zh}" "${base_doc_id}-CN" "../../en/${subdir}/${filename}" "${cn_temporary}"
render_template en "${title_en}" "${base_doc_id}-EN" "../../cn/${subdir}/${filename}" "${en_temporary}"
chmod 0644 "${cn_temporary}" "${en_temporary}"

if ! mv -n "${cn_temporary}" "${cn_destination}" || [ -e "${cn_temporary}" ]; then
  echo "philosophy: CN destination appeared during pair publication" >&2
  exit 1
fi
cn_temporary=""
cn_published="${cn_destination}"
if ! mv -n "${en_temporary}" "${en_destination}" || [ -e "${en_temporary}" ]; then
  rm -f "${cn_destination}"
  cn_published=""
  echo "philosophy: EN publication failed; rolled back the CN document" >&2
  exit 1
fi
en_temporary=""
cn_published=""
trap - EXIT

echo "philosophy: created cn/${subdir}/${filename}"
echo "philosophy: created en/${subdir}/${filename}"
echo "philosophy: complete both semantic projections, then run 'just check'"
