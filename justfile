set shell := ["bash", "-cu"]

# Show the maintained authoring surface.
default:
    @just --list

# Delegate closed-world topology, exact composition, pairing, and assertions to Orgize.
check:
    ./scripts/test-new-philosophy-document.sh
    ./scripts/test-org-contract-negative.sh
    ./scripts/test-trace-org-contract.sh
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
      'topology: optional TOPOLOGY_ID (defaults from DOC_ID)' \
      'charter: PRINCIPLE_REF PRINCIPLE_KIND (refinement also requires REFINES)' \
      'engineering-map: PRINCIPLE_REF' \
      'source-note: SOURCE_AUTHOR SOURCE_WORK SOURCE_LANGUAGE SOURCE_EDITION SOURCE_DATE' \
      'engineering evidence: SOURCE_REPOSITORIES SOURCE_REVISIONS SOURCE_PATHS OBSERVATION_DATE' \
      'synthesis: CONSTITUENT_SOURCES' \
      'source-note optional: SOURCE_ID SOURCE_KIND INTERPRETATION_STATUS CLAIM_SCOPE'

# List document kinds accepted by the scaffolder.
kinds:
    @./scripts/new-philosophy-document.sh --list
