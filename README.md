# PalomarTemplate

[![CI](https://github.com/kim-em/PalomarTemplate/actions/workflows/ci.yml/badge.svg)](https://github.com/kim-em/PalomarTemplate/actions/workflows/ci.yml)

A best-practice starting point for a
[Palomar](https://kim-em.github.io/PalomarWeb/) submission. Use this as a
GitHub template, replace the toy theorem and all `TEMPLATE` metadata, and keep
the separation between the human-auditable statement and the proof.

## Repository map

- `Challenge.lean` is the small statement surface a reader audits.
- `Solution.lean` connects the same declaration to the completed proof.
- `PalomarTemplate/` contains the full proof development.
- `comparator.json` tells Comparator which declarations must match.
- `formalization.yaml` records provenance, authorship, automation, fidelity,
  and review information.
- `LICENSE` contains the Apache License 2.0 terms declared by
  `project.license`.
- `docbuild/` is the recommended nested doc-gen4 project.
- `scripts/verify-comparator.sh` runs pinned Comparator, lean4export, NanoDa,
  and Landrun revisions, and forces the independent NanoDa replay regardless
  of `comparator.json`; `scripts/landrun-wrapper.sh` preserves lean4export's
  command delimiter when invoked through Landrun's current CLI.

The root uses `lakefile.toml`, a supported stable Lean toolchain, and committed
Lake manifests. GitHub Actions builds the Lean project with `lean-action`,
generates API documentation with doc-gen4, and independently checks the
advertised statement with Comparator. Actions and verification tools are pinned
to immutable commits.

## Start a real project

1. Click **Use this template** on GitHub and clone the new repository.
2. Rename `PalomarTemplate` in the Lake package, module directory, namespace,
   Comparator declaration, and metadata.
3. Replace the example library, `Challenge.lean`, and `Solution.lean`.
4. Replace every `TEMPLATE` value in `formalization.yaml`.
   Mark whether the result is original or source-based and whether this is the
   substantive development or a thin wrapper. Original results may remove the
   `sources` list. Remove `related_formalizations` when none are known.
   Apache-2.0 is the template default and is common in the Lean ecosystem. If
   the project uses another licence, replace `LICENSE` and
   `project.license` together with one mechanically recognizable SPDX licence.
5. Update and commit dependency pins:

   ```text
   lake update
   (cd docbuild && MATHLIB_NO_CACHE_ON_UPDATE=1 lake update)
   ```

6. Run the same checks as CI:

   ```text
   lake exe cache get
   lake build
   (cd docbuild && lake build PalomarTemplate:docs)
   ! grep -n 'TEMPLATE:' formalization.yaml
   ./scripts/verify-comparator.sh
   ```

   Run the final command from the repository root. It requires Linux, Git, Go,
   Rust/Cargo, Python 3, and a working Landrun sandbox.

7. Read the current
   [Palomar submission policy](https://github.com/kim-em/PalomarPolicy/blob/main/CONTRIBUTING.md),
   commit the final snapshot, and
   [open the submission form](https://github.com/kim-em/PalomarSubmission/issues/new?template=submit.yml)
   with the full 40-character commit SHA.

   Submit only if you are responsible for the substantive formalization or
   have approval from someone who is. For a thin wrapper, this refers to the
   maintainers of the underlying repository; the form records that relationship
   and allows optional evidence.

## Important boundaries

This repository is structurally valid but its toy theorem does **not** meet
Palomar's editorial floor. A green build or Comparator check establishes only
that Lean accepts the project and that the recorded solution proves the recorded
statement using the permitted axioms. It does not establish mathematical
significance, fidelity to a source, novelty, or peer review.

Keep `Challenge.lean` ordinary and readable. Definitions needed by the statement
must have precise mathematical meanings and docstrings. Palomar-indexed
statement dependencies are allowed but enlarge the trust surface and are
prominently flagged. Dependencies used only by the proof may be arbitrary pinned
Git dependencies.
The root licence covers this repository snapshot only; cited papers, reused
formalizations, and dependencies retain their own licences.

Questions are welcome in the
[Palomar channel on the Lean Zulip](https://leanprover.zulipchat.com/#narrow/channel/621638-Palomar).
