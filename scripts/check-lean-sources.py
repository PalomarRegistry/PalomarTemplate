#!/usr/bin/env python3
"""Check source requirements before builds; full Palomar verification is still required.

Scanner functions follow PalomarSubmission/scripts/source_requirements.py.
"""
import os
import re
from pathlib import Path

COMMENT_MARKER = re.compile(r"/-|-/")


def has_module_header(text: str) -> bool:
    """Recognize the initial marker, without confusing comments with headers.

    Documentation comments are commands, not header whitespace. Do not strip a
    BOM or arbitrary Unicode whitespace: Lean's header parser does not either.
    This cheap check precedes installation; execute confirms with --deps-json.
    """
    index = 0
    while index < len(text):
        if text[index] in " \r\n":
            index += 1
        elif text.startswith("--", index):
            end = text.find("\n", index + 2)
            index = len(text) if end < 0 else end + 1
        elif text.startswith("/-", index) and not text.startswith(("/--", "/-!"), index):
            # Lean consumes the character after the plain opener before
            # scanning its body (unlike nested openers). Match its parser.
            index += 3
            depth = 1
            while depth:
                marker = COMMENT_MARKER.search(text, index)
                if marker is None:
                    break
                depth += 1 if marker.group() == "/-" else -1
                index = marker.end()
            if depth:
                return False
        else:
            return text.startswith("module", index) and (
                index + 6 == len(text)
                or text[index + 6] in " \r\n"
                or text.startswith(("--", "/-"), index + 6)
            )
    return False


def physical_lines(text: str) -> int:
    """LF/CRLF lines; an unterminated final line counts, a final LF adds none."""
    return text.count("\n") + int(bool(text) and not text.endswith("\n"))


def lean_source_files(root: Path) -> list[Path]:
    """Lean source paths, including contained projects and symlinks to reject.

    Lake configuration shares the line cap, but is exempt from module headers.
    Never traverse symlinks or Git internals.
    """
    files = []
    for directory, subdirectories, names in os.walk(root, followlinks=False):
        subdirectories[:] = sorted(
            name for name in subdirectories
            if name not in {".git", ".lake"} and not (Path(directory) / name).is_symlink()
        )
        for name in sorted(names):
            path = Path(directory) / name
            if name.endswith(".lean") and (path.is_symlink() or path.is_file()):
                files.append(path)
    return files


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    failed = False
    for path in lean_source_files(root):
        relative = path.relative_to(root)
        if path.is_symlink():
            print(f"{relative}: must be a regular Lean file, not a symbolic link")
            failed = True
            continue
        try:
            text = path.read_bytes().decode("utf-8")
        except UnicodeDecodeError:
            print(f"{relative}: source is not valid UTF-8")
            failed = True
            continue
        if path.name != "lakefile.lean" and not has_module_header(text):
            print(f"{relative}: must use the module header keyword")
            failed = True
        if physical_lines(text) > 10_000:
            print(f"{relative}: exceeds 10,000 lines; split into smaller modules")
            failed = True
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
