#!/usr/bin/env python3
"""
Apply the Phase 4 allow_skip policy from GRADED_MODE_RUNBOOK.md.

1. allow_skip: true -> false in M5-M10 (M1-M4 already false).
2. Add {data-allow-skip="true"} to the section heading that CONTAINS each
   write-from-scratch exercise named in the runbook's candidate list.

Line endings are preserved byte-for-byte: files are read/written in binary and
only the specific lines are rewritten.

NEVER writes data-allow-skip="false" -- in learnr's tutorial-format.js the
attribute handler assigns a constant, so "false" enables skipping exactly as
"true" does. The attribute can only open a section, never close one.
"""
import re
import sys
import pathlib

# Source of truth is coach-endpoint/exercise_registry.R -- the 17 coached
# exercises -- NOT the runbook's Phase 4 list, which named only 15 and omitted
# module6-q4 and module8-q3. Re-derive from the registry after any renumbering:
#   grep -oE '"module[0-9]+-q[0-9]+"' coach-endpoint/exercise_registry.R
#
# Safe to re-run. The YAML step warns if allow_skip is already false; the
# section step reports "already open" and changes nothing.
CANDIDATES = {
    "04-wrangle-visualize.Rmd": ["q5", "q10"],
    "05-groups.Rmd":            ["q1", "q3"],
    "06-regression.Rmd":        ["q2", "q4", "q5"],
    "07-two-way-anova.Rmd":     ["q1", "q3"],
    "08-ancova.Rmd":            ["q1", "q3", "q4"],
    "09-choosing-a-test.Rmd":   ["q1", "q2", "q3"],
    "10-joining-data.Rmd":      ["q1", "q4"],
}
FLIP_TO_FALSE = [
    "05-groups.Rmd", "06-regression.Rmd", "07-two-way-anova.Rmd",
    "08-ancova.Rmd", "09-choosing-a-test.Rmd", "10-joining-data.Rmd",
]

CHUNK = re.compile(r"^```\{r\s+([A-Za-z0-9_.-]+)")
HEADING = re.compile(r"^##\s+(?!#)")
SKIP_YAML = re.compile(r"^(\s*)allow_skip:\s*true\s*$")


def process(path: pathlib.Path, report):
    raw = path.read_bytes()
    crlf = b"\r\n" in raw
    text = raw.decode("utf-8")
    eol = "\r\n" if crlf else "\n"
    lines = text.split(eol)
    name = path.name

    # --- 1. YAML flip -------------------------------------------------------
    if name in FLIP_TO_FALSE:
        done = False
        for i, ln in enumerate(lines[:30]):
            m = SKIP_YAML.match(ln)
            if m:
                lines[i] = f"{m.group(1)}allow_skip: false"
                report.append(f"  [yaml]     line {i+1}: allow_skip true -> false")
                done = True
                break
        if not done:
            report.append("  [yaml]     WARNING: no 'allow_skip: true' found -- check manually")

    # --- 2. Per-section overrides ------------------------------------------
    # Map each target exercise chunk to the nearest preceding '## ' heading.
    targets = CANDIDATES.get(name, [])
    heading_for = {}
    last_heading = None
    for i, ln in enumerate(lines):
        if HEADING.match(ln):
            last_heading = i
        m = CHUNK.match(ln)
        if m and m.group(1) in targets and last_heading is not None:
            # first (defining) chunk wins; -hint/-check share the label prefix
            heading_for.setdefault(m.group(1), last_heading)

    for label in targets:
        idx = heading_for.get(label)
        if idx is None:
            report.append(f"  [section]  WARNING: chunk '{label}' not found under any '## ' heading")
            continue
        h = lines[idx]
        if "data-allow-skip" in h:
            report.append(f"  [section]  {label}: already open -- '{h.strip()[:52]}'")
            continue
        lines[idx] = h.rstrip() + ' {data-allow-skip="true"}'
        report.append(f"  [section]  {label}: line {idx+1} -> {lines[idx].strip()[:78]}")

    path.write_bytes(eol.join(lines).encode("utf-8"))
    return crlf


if __name__ == "__main__":
    root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    for f in sorted(set(FLIP_TO_FALSE) | set(CANDIDATES)):
        p = root / f
        if not p.exists():
            print(f"{f}: MISSING")
            continue
        rep = []
        crlf = process(p, rep)
        print(f"{f}  ({'CRLF' if crlf else 'LF'} preserved)")
        for line in rep:
            print(line)
        print()
