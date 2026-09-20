# Philosophy repository authoring rules

- Normative and discursive content is authored in Org, not Markdown.
- Every maintained content document composes `philosophy.document.v1` and its
  purpose-specific contract on one `CONTRACT_ORG` property line.
- Chinese and English live under `cn/` and `en/`. Each pair shares one
  `SEMANTIC_ID` and has reciprocal `COUNTERPART` paths.
- Put accepted cross-project principles in `cn|en/10-charter/`, engineering
  consequences in `cn|en/20-engineering/`, unsettled work in
  `cn|en/30-reflections/`, and interpreted sources in `cn|en/40-sources/`.
- Do not promote a reflection into the charter by changing only its path or
  `DOC_KIND`. Rewrite it against `philosophy.charter.v1` and preserve the
  counterargument, failure-mode, and traceability sections.
- Contract and template changes are paired. Update `org/contracts/` and the
  corresponding `org/templates/` file in the same change.
- Use `just new` to create the CN/EN pair instead of copying a template by hand.
- Run `just check` before treating a document change as valid. The gate uses
  `tao3k/orgize`; it must not be replaced by a second Org parser.
