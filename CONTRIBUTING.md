# Adapting this template

1. Rename the package and namespace throughout the repository.
2. Put the proof development in the library and import it from `Solution.lean`.
3. Rewrite `Challenge.lean` as a small, independently auditable statement
   surface. Its imports must satisfy the current Palomar policy.
4. Update `comparator.json` with every advertised theorem and any definition
   holes. Definition holes require special editorial scrutiny.
5. Replace every `TEMPLATE` value in `formalization.yaml` with honest,
   independently checkable metadata. Run
   `ruby scripts/validate-formalization.rb`; it parses the file and lists every
   retained sentinel, including deliberately invalid classification, proof,
   automation, and review defaults. Replace a placeholder list with `[]` only
   when none is the honest answer. Keep the Apache-2.0 `LICENSE` file and the
   matching `project.license: "Apache-2.0"` metadata. This starter template
   supports only that root licence. A project deliberately using another root
   licence permitted by Palomar policy needs another starting point or must
   own and maintain its licence-validation CI contract.
6. Run `lake update` and `cd docbuild && lake update` after changing dependencies,
   then commit both manifest files.
7. Run `lake build`, build the docs, and run Comparator before submitting to
   Palomar.

Do not submit the toy theorem unchanged. Palomar applies a substantive
research-interest floor in addition to mechanical verification.
