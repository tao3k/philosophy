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

# Create a contract-shaped document. Set TITLE_ZH, TITLE_EN, and optionally AUTHOR.
new kind filename doc_id:
    ./scripts/new-philosophy-document.sh "{{kind}}" "{{filename}}" "{{doc_id}}"

# List document kinds accepted by the scaffolder.
kinds:
    @./scripts/new-philosophy-document.sh --list
