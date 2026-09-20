set shell := ["bash", "-cu"]

# Show the maintained authoring surface.
default:
    @just --list

# Delegate closed-world topology, exact composition, pairing, and assertions to Orgize.
check:
    ./scripts/test-new-philosophy-document.sh
    ./scripts/check-org-contracts.sh

# Print the parser-owned contract trace for one document.
trace document:
    ./scripts/trace-org-contract.sh "{{document}}"

# Create a paired contract-shaped document. Run `just new-help` for required inputs.
new kind filename doc_id:
    ./scripts/new-philosophy-document.sh "{{kind}}" "{{filename}}" "{{doc_id}}"

# Show common and kind-specific inputs for `just new`.
new-help:
    @printf '%s\n' \
      'common: TITLE_ZH TITLE_EN (optional: AUTHOR)' \
      'charter: PRINCIPLE_REF REFINES' \
      'engineering-map: PRINCIPLE_REF' \
      'source-note: SOURCE_AUTHOR SOURCE_WORK SOURCE_LANGUAGE' \
      'source-note optional: SOURCE_ID SOURCE_KIND SOURCE_EDITION SOURCE_DATE INTERPRETATION_STATUS CLAIM_SCOPE'

# List document kinds accepted by the scaffolder.
kinds:
    @./scripts/new-philosophy-document.sh --list
