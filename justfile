set shell := ["bash", "-cu"]

# Show the maintained authoring surface.
default:
    @just --list

# Fast qualification: verify the pinned parser and one stable AST workspace receipt.
check:
    ./scripts/check-orgize-toolchain.sh
    ./scripts/check-workspace-receipt.sh

# Repository acceptance is the pinned Orgize workspace receipt. Orgize owns
# contract-engine fixtures and negative scenarios; this repository owns policy.
test: check

# Print the parser-owned workspace evaluation for human inspection.
contract:
    ./scripts/check-org-contracts.sh

# Install the exact Orgize revision declared by the Org toolchain contract.
toolchain-install:
    ./scripts/install-orgize-toolchain.sh

# Refresh the stable machine qualification receipt after an intentional change.
receipt:
    ./scripts/update-workspace-receipt.sh

# Print the parser-owned contract trace for one document.
trace document:
    ./scripts/trace-org-contract.sh "{{document}}"

# Create a paired contract-shaped document. Run `just new-help` for required inputs.
new kind filename doc_id:
    ./scripts/new-philosophy-document.sh "{{kind}}" "{{filename}}" "{{doc_id}}"

# Show common and kind-specific inputs for `just new`.
new-help:
    @printf '%s\n' \
      'paired kinds: TITLE_ZH TITLE_EN (optional: AUTHOR)' \
      'repository-index: TITLE; renders the singleton README.org' \
      'topology: optional TOPOLOGY_ID (defaults from DOC_ID)' \
      'charter: PRINCIPLE_REF PRINCIPLE_KIND (refinement also requires REFINES)' \
      'engineering-map: PRINCIPLE_REF' \
      'ai-object-reflection: INTERACTION_OBJECTS' \
      'source-note: SOURCE_AUTHOR SOURCE_WORK SOURCE_LANGUAGE SOURCE_EDITION SOURCE_DATE' \
      'engineering evidence: SOURCE_REPOSITORIES SOURCE_REVISIONS SOURCE_PATHS OBSERVATION_DATE' \
      'synthesis: CONSTITUENT_SOURCES' \
      'source-note optional: SOURCE_ID SOURCE_KIND INTERPRETATION_STATUS CLAIM_SCOPE'

# List document kinds accepted by the scaffolder.
kinds:
    @./scripts/new-philosophy-document.sh --list
