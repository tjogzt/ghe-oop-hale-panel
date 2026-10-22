#!/usr/bin/env python3
"""Build the Word version of the manuscript with images that actually render.

Why this exists
---------------
pandoc's docx writer cannot embed PDF images. When it meets
`\\includegraphics{.../fig.pdf}` it only converts to PNG if a *sibling*
`fig.png` exists next to the PDF; otherwise it copies the PDF straight into
word/media/ and Word shows a blank frame. Journals that ask for .docx then get
a manuscript with invisible figures.

This script therefore:
  1. rewrites every `\\includegraphics{....pdf}` to the PNG twin under
     results/figures/png/ into a throwaway .tex,
  2. runs pandoc on that copy,
  3. asserts that every image in the resulting .docx really is a PNG,
     reporting pixel sizes so a stale figure cannot slip through,
  4. deletes the throwaway .tex.

Usage:  python3 code/make_docx.py
"""
import os
import re
import struct
import subprocess
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MS = os.path.join(ROOT, "manuscript")
TEX = os.path.join(MS, "main_manuscript.tex")
TMP_TEX = os.path.join(MS, "_docx_tmp.tex")
PNG_DIR = os.path.join(ROOT, "results", "figures", "png")
OUT = os.path.join(ROOT, "submission", "bulletin_who", "main_manuscript.docx")


def main():
    src = open(TEX, encoding="utf-8").read()

    # pandoc does not know this project's custom macros, and leaves them as raw
    # LaTeX in the .docx (Word then shows "+0{\\textperiodcentered{}}41" instead of
    # "+0.41"). Normalise them to plain text/Unicode before conversion.
    macro_map = {
        "{\\textperiodcentered{}}": ".",   # Lancet-style decimal separator
        "\\textperiodcentered{}": ".",
        "\\textperiodcentered": ".",
        "\\beta": "\u03b2",
        "\\alpha": "\u03b1",
        "\\delta": "\u03b4",
        "\\gamma": "\u03b3",
        "\\dagger": "\u2020",
        "\\times": "\u00d7",
        "\\approx": "\u2248",
        "\\geq": "\u2265",
        "\\leq": "\u2264",
        "\\pm": "\u00b1",
    }
    for k, v in macro_map.items():
        src = src.replace(k, v)

    # PDF -> PNG twin
    rewritten = []
    def repl(m):
        path = m.group(1)
        name = os.path.basename(path).replace(".pdf", "") + ".png"
        png = os.path.join(PNG_DIR, name)
        if not os.path.exists(png):
            sys.exit(f"FAIL: no PNG twin for {path} (expected {png})")
        rewritten.append(name)
        return m.group(0).replace(path, "../results/figures/png/" + name)

    out = re.sub(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+\.pdf)\}", repl, src)
    print(f"figures rewritten to PNG: {len(rewritten)} -> {rewritten}")

    open(TMP_TEX, "w", encoding="utf-8").write(out)
    try:
        r = subprocess.run(
            ["pandoc", "_docx_tmp.tex", "-o", OUT, "--from=latex", "--to=docx",
             f"--resource-path=.:{PNG_DIR}"],
            cwd=MS, capture_output=True, text=True)
        warns = [l for l in (r.stdout + r.stderr).splitlines()
                 if l.strip() and "textperiodcentered" not in l and not l.strip().startswith("^")]
        for w in warns[:4]:
            print("  pandoc:", w[:110])
    finally:
        os.remove(TMP_TEX)

    # verify every embedded image is a PNG
    print("\nverifying embedded images ...")
    z = zipfile.ZipFile(OUT)
    png = other = 0
    for n in sorted(z.namelist()):
        if not n.startswith("word/media/"):
            continue
        d = z.read(n)
        if d[:8] == b"\x89PNG\r\n\x1a\n":
            png += 1
            w, h = struct.unpack(">II", d[16:24])
            print(f"  {n.split('/')[-1]:<12} PNG {w}x{h}  ({w/300*25.4:.0f}x{h/300*25.4:.0f} mm)")
        else:
            other += 1
            print(f"  {n.split('/')[-1]:<12} NOT PNG  magic={d[:5]}  <-- Word cannot render this")
    print(f"\nPNG={png}  non-PNG={other}")
    ok = (other == 0 and png == len(rewritten))
    print("->  PASS" if ok else f"->  FAIL (expected {len(rewritten)} PNGs)")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
