#!/usr/bin/env bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ "${1:-}" = "--list" ]; then
  printf '%s\n' charter engineering-map reflection source-note governance
  exit 0
fi

kind="${1:-}"
filename="${2:-}"
base_doc_id="${3:-}"
title_zh="${TITLE_ZH:-}"
title_en="${TITLE_EN:-}"
author="${AUTHOR:-Tao3k}"

if [ -z "${kind}" ] || [ -z "${filename}" ] || [ -z "${base_doc_id}" ]; then
  echo "usage: TITLE_ZH='...' TITLE_EN='...' just new <kind> <NN.name.org> <DOC_ID>" >&2
  exit 2
fi
if [ -z "${title_zh}" ] || [ -z "${title_en}" ]; then
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
  charter) subdir="10-charter" ;;
  engineering-map) subdir="20-engineering" ;;
  reflection) subdir="30-reflections" ;;
  source-note) subdir="40-sources" ;;
  governance) subdir="90-governance" ;;
  *) echo "philosophy: unsupported kind '${kind}'; run 'just kinds'" >&2; exit 2 ;;
esac

cn_destination="${repository_root}/cn/${subdir}/${filename}"
en_destination="${repository_root}/en/${subdir}/${filename}"
if [ -e "${cn_destination}" ] || [ -e "${en_destination}" ]; then
  echo "philosophy: refusing to overwrite an existing CN/EN document pair" >&2
  exit 1
fi

semantic_id="${SEMANTIC_ID:-philosophy.${kind}.${filename%.org}}"
principle_ref="${PRINCIPLE_REF:-}"
refines="${REFINES:-}"
source_id="${SOURCE_ID:-${base_doc_id}}"
source_kind="${SOURCE_KIND:-SYNTHESIS}"
source_author="${SOURCE_AUTHOR:-}"
source_work="${SOURCE_WORK:-}"
source_language="${SOURCE_LANGUAGE:-}"
source_date="${SOURCE_DATE:-}"
today="$(date -u +%Y-%m-%d)"

require_input() {
  local name="$1"
  local value="$2"
  if [ -z "${value}" ]; then
    echo "philosophy: ${name} is required for ${kind}" >&2
    exit 2
  fi
}

case "${kind}" in
  charter)
    require_input PRINCIPLE_REF "${principle_ref}"
    require_input REFINES "${refines}"
    ;;
  engineering-map)
    require_input PRINCIPLE_REF "${principle_ref}"
    ;;
  source-note)
    require_input SOURCE_AUTHOR "${source_author}"
    require_input SOURCE_WORK "${source_work}"
    require_input SOURCE_LANGUAGE "${source_language}"
    source_date="${source_date:-${today}}"
    case "${source_kind}" in
      PRIMARY|SECONDARY|SYNTHESIS|ENGINEERING_EVIDENCE) ;;
      *)
        echo "philosophy: SOURCE_KIND must be PRIMARY, SECONDARY, SYNTHESIS, or ENGINEERING_EVIDENCE" >&2
        exit 2
        ;;
    esac
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
  local destination="$5"
  local template="${repository_root}/org/templates/philosophy.${kind}.${locale}.v1.org"
  local temporary_file="$6"

  sed \
    -e "s|<TITLE>|$(escape_sed_replacement "${title}")|g" \
    -e "s|<AUTHOR>|$(escape_sed_replacement "${author}")|g" \
    -e "s|<DATE>|${today}|g" \
    -e "s|<DOC_ID>|$(escape_sed_replacement "${doc_id}")|g" \
    -e "s|<SEMANTIC_ID>|$(escape_sed_replacement "${semantic_id}")|g" \
    -e "s|<COUNTERPART>|$(escape_sed_replacement "${counterpart}")|g" \
    -e "s|<PRINCIPLE_REF>|$(escape_sed_replacement "${principle_ref}")|g" \
    -e "s|<REFINES>|$(escape_sed_replacement "${refines}")|g" \
    -e "s|<SOURCE_ID>|$(escape_sed_replacement "${source_id}")|g" \
    -e "s|<SOURCE_KIND>|$(escape_sed_replacement "${source_kind}")|g" \
    -e "s|<SOURCE_AUTHOR>|$(escape_sed_replacement "${source_author}")|g" \
    -e "s|<SOURCE_WORK>|$(escape_sed_replacement "${source_work}")|g" \
    -e "s|<SOURCE_EDITION>|$(escape_sed_replacement "${SOURCE_EDITION:-1}")|g" \
    -e "s|<SOURCE_DATE>|$(escape_sed_replacement "${source_date}")|g" \
    -e "s|<SOURCE_LANGUAGE>|$(escape_sed_replacement "${source_language}")|g" \
    -e "s|<INTERPRETATION_STATUS>|$(escape_sed_replacement "${INTERPRETATION_STATUS:-MODERNIZED}")|g" \
    -e "s|<CLAIM_SCOPE>|$(escape_sed_replacement "${CLAIM_SCOPE:-${semantic_id}}")|g" \
    -e "s|<GOVERNANCE_ID>|$(escape_sed_replacement "${GOVERNANCE_ID:-${base_doc_id}}")|g" \
    -e "s|<LIFECYCLE_ID>|$(escape_sed_replacement "${LIFECYCLE_ID:-${base_doc_id}.lifecycle}")|g" \
    -e "s|<CUSTOM_ID>|$(escape_sed_replacement "${semantic_id}-${locale}")|g" \
    "${template}" > "${temporary_file}"
}

cn_temporary="$(mktemp "${TMPDIR:-/tmp}/philosophy-cn.XXXXXX")"
en_temporary="$(mktemp "${TMPDIR:-/tmp}/philosophy-en.XXXXXX")"
trap 'rm -f "${cn_temporary}" "${en_temporary}"' EXIT

render_template cn "${title_zh}" "${base_doc_id}-CN" "../../en/${subdir}/${filename}" "${cn_destination}" "${cn_temporary}"
render_template en "${title_en}" "${base_doc_id}-EN" "../../cn/${subdir}/${filename}" "${en_destination}" "${en_temporary}"

mv "${cn_temporary}" "${cn_destination}"
mv "${en_temporary}" "${en_destination}"
trap - EXIT

echo "philosophy: created cn/${subdir}/${filename}"
echo "philosophy: created en/${subdir}/${filename}"
echo "philosophy: complete both semantic projections, then run 'just check'"
