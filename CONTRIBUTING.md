# Adapting this template

1. Rename the package and namespace throughout the repository.
2. Put the proof development in the library and import it from `Solution.lean`.
3. Rewrite `Challenge.lean` as a small, independently auditable statement
   surface. Its imports must satisfy the current Palomar policy.
4. Update `comparator.json` with every advertised theorem and any definition
   holes. Definition holes require special editorial scrutiny.
5. Replace every `TEMPLATE` value in `formalization.yaml` with honest,
   independently checkable metadata. The template defaults to Apache-2.0; if
   changing the repository licence, replace both `LICENSE` and
   `project.license` with one matching standard SPDX licence.
6. Run `lake update` and `cd docbuild && lake update` after changing dependencies,
   then commit both manifest files.
7. Run `lake build`, build the docs, and run Comparator before opening a
   Palomar submission issue.

Do not submit the toy theorem unchanged. Palomar applies a substantive
research-interest floor in addition to mechanical verification.
