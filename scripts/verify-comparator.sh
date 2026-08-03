#!/usr/bin/env bash
set -euo pipefail

repository_root=$(cd "$(dirname "$0")/.." && pwd)
cache_root=${PALOMAR_COMPARATOR_CACHE:-"$repository_root/.cache/palomar-comparator"}
bin_dir="$cache_root/bin"
comparator_dir="$cache_root/comparator"
lean4export_dir="$cache_root/lean4export"
nanoda_dir="$cache_root/nanoda"
enforced_config="$cache_root/enforced-comparator.json"

comparator_commit=68a064109f01c08f47c8edc9f51d6a2bbffaa188
lean4export_commit=4e7915201d3f9f04470d9eae002fa695f7cdc589
landrun_commit=811cfff51ceaf3d9843708aa6d22e9b84ccac8b4
nanoda_commit=68d5ca9db226849b41a6fff59d796ff19d0a8840
expected_toolchain=leanprover/lean4:v4.32.0

actual_toolchain=$(tr -d '[:space:]' < "$repository_root/lean-toolchain")
if [ "$actual_toolchain" != "$expected_toolchain" ]; then
  echo "error: no pinned lean4export revision is configured for $actual_toolchain" >&2
  echo "update the tool pins for the new Lean toolchain before running Comparator" >&2
  exit 1
fi

for required_command in cargo git go lake python3; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    echo "error: $required_command is required to run Comparator" >&2
    exit 1
  fi
done

mkdir -p "$cache_root" "$bin_dir"

checkout_exact() {
  local repository=$1
  local destination=$2
  local commit=$3
  if [ ! -d "$destination/.git" ]; then
    git clone --filter=blob:none "$repository" "$destination"
  fi
  git -C "$destination" fetch --depth 1 origin "$commit"
  git -C "$destination" checkout --detach "$commit"
}

checkout_exact https://github.com/leanprover/comparator.git "$comparator_dir" "$comparator_commit"
checkout_exact https://github.com/leanprover/lean4export.git "$lean4export_dir" "$lean4export_commit"
checkout_exact https://github.com/robsimmons/nanoda_lib.git "$nanoda_dir" "$nanoda_commit"

GOBIN="$bin_dir" go install "github.com/zouuup/landrun/cmd/landrun@$landrun_commit"

(cd "$comparator_dir" && lake build comparator)
(cd "$lean4export_dir" && lake build lean4export)
(cd "$nanoda_dir" && cargo build --release --locked)

# NanoDa is a verifier policy, not a submitter-controlled Comparator option.
# Preserve comparator.json itself while forcing the independent replay in the
# runner-owned copy passed to Comparator.
python3 - "$repository_root/comparator.json" "$enforced_config" <<'PY'
import json
import pathlib
import sys

source, destination = map(pathlib.Path, sys.argv[1:])
config = json.loads(source.read_text(encoding="utf-8"))
config["enable_nanoda"] = True
destination.write_text(json.dumps(config, indent=2) + "\n", encoding="utf-8")
PY

cd "$repository_root"
lake exe cache get
PALOMAR_LANDRUN_BIN="$bin_dir/landrun" \
COMPARATOR_LEAN4EXPORT="$lean4export_dir/.lake/build/bin/lean4export" \
COMPARATOR_NANODA="$nanoda_dir/target/release/nanoda_bin" \
COMPARATOR_LANDRUN="$repository_root/scripts/landrun-wrapper.sh" \
  lake env "$comparator_dir/.lake/build/bin/comparator" "$enforced_config"
