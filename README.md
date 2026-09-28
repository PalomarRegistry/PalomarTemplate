# PalomarTemplate

[![CI](https://github.com/PalomarRegistry/PalomarTemplate/actions/workflows/ci.yml/badge.svg)](https://github.com/PalomarRegistry/PalomarTemplate/actions/workflows/ci.yml)

A best-practice starting point for a
[Palomar](https://palomar-registry.org/) submission. Use this as a
GitHub template, replace the toy theorem and all `TEMPLATE` metadata, and keep
the separation between the human-auditable statement and the proof.

## Repository map

- `Challenge.lean` is the small statement surface a reader audits.
- `Solution.lean` connects the same declaration to the completed proof.
- `PalomarTemplate/` contains the full proof development.
- `comparator.json` tells `lake comparator` which declarations must match.
- `formalization.yaml` records the public result description, provenance,
  authorship, automation, fidelity, and review information.
- `LICENSE` contains the Apache License 2.0 terms declared by
  `project.license`.
- `docbuild/` is the recommended nested doc-gen4 project.
- `scripts/verify-comparator.sh` runs the `lake comparator` that ships in
  this project's own toolchain over the checked-in `comparator.json`,
  registering the toolchain's bundled independent kernels (NanoDa and con-ron)
  exactly as Palomar does; the optional `enable_nanoda` field is ignored, and
  `external_kernels` is not a submitter field.

The root uses `lakefile.toml`, a supported Lean toolchain (Palomar requires
`leanprover/lean4:v4.35.0-rc2` or later, which is where `lake comparator`
appears), and committed Lake manifests. Everything that judges a submission
comes from `lean-toolchain`; there is no separate verifier pin to keep in step
with it. GitHub Actions builds the Lean project with `lean-action`, generates
API documentation with doc-gen4, and independently checks the advertised
statement with `lake comparator`. Actions are pinned to immutable commits.

## Start a real project

1. Click **Use this template** on GitHub and clone the new repository.
2. Rename `PalomarTemplate` in the Lake package, module directory, namespace,
   Comparator declaration, and metadata.
3. Replace the example library, `Challenge.lean`, and `Solution.lean`.
   Keep `Challenge.lean` as the small statement-only surface, with one `sorry`
   for each advertised declaration; put the proofs in `Solution.lean`, where
   Comparator checks them against those statements. The proof-status counts in
   `formalization.yaml` exclude the deliberate Challenge `sorry`s.
4. Replace every `TEMPLATE` value in `formalization.yaml`. Values that might
   otherwise look like plausible defaults—including repository role,
   classifications, proof counts, automation method, and review status—are
   deliberately invalid until you choose them. Replace a placeholder list with
   an empty list only where its adjacent comment permits that; lists described
   as required must remain nonempty.
   Write `project.description` as the concise public registry abstract for the
   formalization as a whole. It should let a mathematical reader identify the
   subject and principal result families; it is not an inventory of Comparator
   declarations, and the README and Challenge documentation can carry the
   fuller account. `status.main_results` is optional: add it only when a short
   curated project-level list is useful, not to mirror Comparator declarations.
   The `sources` list must remain nonempty. Every source relationship must be
   exactly `formalizes`, `adapts`, `independently-proves`, `background`, or
   `other`. Choose one result origin: for a result first presented by the
   formalization, include a descriptive source with `type: original-proof` and
   `relationship: other`; every additional source must use `background` or
   `other`. Otherwise, omit `type: original-proof`, and give at least one cited
   mathematical source a `formalizes`, `adapts`, or `independently-proves`
   relationship. A new proof of a known published result is source-based and
   uses `independently-proves`, not `original-proof`.

   Every source needs a title and relationship. Its `type`, authors,
   contributors, identifier, location, licence, and endorsement may be removed
   when genuinely inapplicable. Use authors only for bibliographic authorship;
   use contributors with a name and free-form role for credits such as editors
   and problem proposers. A retained type is a concise free-text description
   such as `article`, `paper`, `book`, `formalization`, `web post`,
   `folklore`, or `conversation`. The exact value `original-proof` is
   reserved for the result-origin declaration above. Set
   `repository.role` to `substantive-development` and omit
   `substantive_formalization`, or set it to `thin-wrapper` and provide the
   underlying `owner/repository` or `https://github.com/owner/repository` URL
   plus its full 40-character lowercase commit SHA. Remove
   `related_formalizations` or set it to `[]` when none are known.
   Keep the repository's Apache-2.0 `LICENSE` file and the matching
   `project.license: "Apache-2.0"` metadata. This starter template supports
   only that root licence. If the project deliberately uses another root
   licence permitted by Palomar policy, use another starting point or own and
   maintain the project's licence-validation CI contract. Cited sources and
   dependencies retain their own licences.
5. Update and commit dependency pins:

   Before fetching and building the dependency closure, budget several GiB of
   free space. After the root cache fetch and build, a clean local checkout of
   the template's pinned manifest occupied about 7.7 GiB across about 123,000
   files under `.lake/` when last measured, on Lean v4.32.0. The documentation
   build adds doc-gen4 and its dependency closure under the shared
   `.lake/packages/` plus generated output under `docbuild/.lake/`. The
   precise footprint changes with the filesystem, cache contents, and any
   dependency updates. Both `.lake/` directories are generated and must not be
   committed.

   ```text
   lake update
   (cd docbuild && MATHLIB_NO_CACHE_ON_UPDATE=1 lake update)
   ```

6. Run the project checks before submitting:

   ```text
   lake exe cache get
   lake build
   (cd docbuild && lake build PalomarTemplate:docs)
   ruby scripts/validate-formalization.rb
   ./scripts/verify-comparator.sh
   ```

   The metadata command parses the YAML, requires the Apache-2.0 root-licence
   declaration, and reports the path of every retained template sentinel. CI
   also detects the checked-in `LICENSE` file independently and runs an
   explicit `--expect-template` check only in the canonical
   `PalomarRegistry/PalomarTemplate` repository, proving that the shipped toy
   metadata still has exactly the intended sentinel surface. Pull requests
   from contribution forks run in that upstream repository context. Every
   other repository—including standalone forks and repositories made with
   **Use this template**—runs the ordinary command and requires every sentinel
   to be replaced. CI also runs the corresponding build, documentation, cache,
   and `lake comparator` checks. Run the final command from the repository
   root. The full check set requires Linux, Git, Ruby, Python 3, and
   `bwrap` (bubblewrap), which `lake comparator` uses to sandbox the build it
   judges.

   The pinned `lean-action` likewise runs `lake exe cache get` in CI and caches
   `.lake/`. A successful canonical starter run deliberately includes the
   statement-surface `sorry` warning and demonstrates the wiring, not submission
   completeness.

7. Read the current
   [Palomar submission policy](https://github.com/PalomarRegistry/PalomarPolicy/blob/main/CONTRIBUTING.md),
   commit the final snapshot, and
   [open the submission form](https://submit.palomar-registry.org/)
   with the full 40-character commit SHA.

   Submit only if you are a responsible author or maintainer of the substantive
   formalization, or have approval from one. For a thin wrapper, answer about
   the underlying formalization rather than the wrapper; the form records that
   relationship and allows optional evidence.

## Important boundaries

This repository is structurally valid but its toy theorem does **not** meet
Palomar's editorial floor. A green build or Comparator check establishes only
that Lean accepts the project and that the recorded solution proves the recorded
statement using the permitted axioms. It does not establish mathematical
significance, fidelity to a source, novelty, or peer review.

Keep `Challenge.lean` ordinary and readable. Definitions needed by the statement
must have precise mathematical meanings and docstrings. Its transitive imports
must resolve to Lean core, Mathlib, Tau Ceti, or CSLib; a Tau Ceti or CSLib
import enlarges the trust surface and is prominently flagged. Dependencies used
only by the proof may be arbitrary pinned Git dependencies.
The root licence covers this repository snapshot only; cited papers, reused
formalizations, and dependencies retain their own licences.

Questions are welcome in the
[Palomar channel on the Lean Zulip](https://leanprover.zulipchat.com/#narrow/channel/621638-Palomar).

## Module system and file sizes

Every regular `.lean` source file in the submitted repository must use Lean's
module system and contain at most **10,000 physical lines**. This includes
Challenge, Solution, unused source files, generated certificates, contained
projects, and local path dependencies. Ordinary comments may precede the
`module` header; module documentation belongs after it. Blank and comment lines
count. LF and CRLF each delimit one line; an unterminated final line counts,
and a final newline does not add an empty line.

Lake configuration files named `lakefile.lean` are exempt from the module
header requirement, but still have the 10,000-line cap. Files below `.git` or
`.lake` are excluded; submitted `.lean` symbolic links are rejected so a link
cannot hide an oversized source file. Separately declared
substantive source repositories for thin wrappers receive the same checks.
External pinned Git dependencies are outside this per-file limit; Lean still
checks their compatibility with the module system. The existing Challenge
limits of **1,000 lines and 100 KiB** also apply.

Porting requires more than adding `module`: make the declarations needed by
other modules public, use `public import` where the public interface needs an
import, and expose definitions whose bodies clients need. See
[Lean's modules and visibility reference](https://lean-lang.org/doc/reference/latest/Source-Files-and-Modules/#modules-and-visibility).
Rebuild and rerun Comparator after porting. Split oversized files into smaller
modules or reduce generated certificates; do not hide them in excluded paths.

The submission form and HTTPS intake check a bounded subset of the submitted
repository at the exact commit and report incomplete scans explicitly. They do
not scan separately declared substantive repositories; preparation checks those. The verifier scans the complete
checkout before builds and confirms headers with Lean's parser before running
submitted Lake code. Violations identify the file and require a corrected new
commit. These rules apply to new ordinary submissions and revisions; metadata
corrections retain their registered source and are not retroactively rejected.

Run `python3 scripts/check-lean-sources.py` before `lake build`. CI repeats this
non-executing check before installing dependencies or building. The supplied
modules use public imports and declarations; keep this structure as you add
files. This local check complements the full Palomar reusable workflow.
