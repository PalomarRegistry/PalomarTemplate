# Adapting this template

1. Rename the package and namespace throughout the repository.
2. Put the proof development in the library and import it from `Solution.lean`.
3. Rewrite `Challenge.lean` as a small, independently auditable statement
   surface. Keep its advertised declarations statement-only with `sorry`; the
   corresponding proofs belong in `Solution.lean`. Its imports must satisfy the
   current Palomar policy.
4. Update `comparator.json` with every advertised theorem and any definition
   holes. Definition holes require special editorial scrutiny.
5. Replace every `TEMPLATE` value in `formalization.yaml` with honest,
   independently checkable metadata. Run
   `ruby scripts/validate-formalization.rb`; it parses the file and lists every
   retained sentinel, including deliberately invalid classification, proof,
   automation, and review defaults. Replace a placeholder list with `[]` only
   where its adjacent comment permits that; lists described as required must
   remain nonempty. In particular, follow the result-origin instructions beside
   `sources` rather than replacing that list with `[]`. Keep the Apache-2.0
   `LICENSE` file and the matching `project.license: "Apache-2.0"` metadata.
   This starter template supports only that root licence. A project deliberately
   using another root licence permitted by Palomar policy needs another starting
   point or must own and maintain its licence-validation CI contract. Leave the
   `repository` example commented out unless this repository is only a wrapper
   around a separately pinned substantive formalization.
6. Run `lake update` and `cd docbuild && lake update` after changing dependencies,
   then commit both manifest files.
7. Run `lake build`, build the docs, and run Comparator before submitting to
   Palomar.

Do not submit the toy theorem unchanged. Palomar applies a substantive
research-interest floor in addition to mechanical verification.

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
