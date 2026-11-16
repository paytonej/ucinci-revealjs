#!/usr/bin/env python3
"""Repair the TrueType font subsets that LuaLaTeX embeds in a PDF.

LuaLaTeX (luahbtex 1.24) subsets TrueType fonts but leaves entries in each subset's
'cmap' table that point past the subset's last glyph (and writes no 'post' table). Most viewers never read that
table, but Adobe Acrobat does when it prints or preflights a file, and reports
"Cannot extract the embedded font 'XXXXXX+FontName'". This drops the out-of-range
cmap entries (which map to no glyph anyway), adds a minimal 'post' table, and appends
the repaired fonts to the PDF as an incremental update; the text, layout, PDF version,
and tagging are unchanged.

Usage: fix_pdf_fonts.py file.pdf [more.pdf ...]   (each file is repaired in place)
Without arguments (as a Quarto post-render script), repairs QUARTO_PROJECT_OUTPUT_FILES.
Needs pypdf and fontTools.
"""
import io, os, sys
try:
    from pypdf import PdfWriter
    from pypdf.generic import NameObject
    from fontTools.ttLib import TTFont, newTable
except ImportError as e:      # never fail a render over this: warn and leave the PDFs as they are
    print(f"fix_pdf_fonts.py: skipped ({e}); install pypdf and fonttools in the Python that Quarto uses")
    sys.exit(0)


def fix_font(data):
    """Return repaired font bytes, or None if the font needed no change."""
    font = TTFont(io.BytesIO(data))
    if "cmap" not in font:
        return None
    glyphs = set(font.getGlyphOrder())
    changed = False
    for table in font["cmap"].tables:
        bad = [code for code, name in table.cmap.items() if name not in glyphs]
        for code in bad:
            del table.cmap[code]
        changed |= bool(bad)
    if "post" not in font:                 # optional in a PDF, but strict font checkers expect it
        post = newTable("post")
        post.formatType = 3.0
        post.italicAngle = 0
        post.underlinePosition = -100
        post.underlineThickness = 50
        post.isFixedPitch = 0
        post.minMemType42 = post.maxMemType42 = post.minMemType1 = post.maxMemType1 = 0
        font["post"] = post
        changed = True
    if not changed:
        return None
    out = io.BytesIO()
    font.save(out)
    return out.getvalue()


def fix_pdf(path):
    # an incremental update: the repaired fonts are appended to the original file, so
    # everything else (PDF version, tagging, structure) is left exactly as it was
    writer = PdfWriter(path, incremental=True)
    fixed, seen = [], set()
    reader = writer._reader
    for num in range(1, reader.trailer["/Size"]):   # every indirect object, including fonts in XObjects
        try:
            obj = writer.get_object(num)
        except Exception:
            continue
        if obj is None or not hasattr(obj, "get") or obj.get("/Type") != "/FontDescriptor":
            continue
        ref = obj.get("/FontFile2")
        if ref is None:
            continue
        stream = ref.get_object()
        if id(stream) in seen:
            continue
        seen.add(id(stream))
        new = fix_font(stream.get_data())
        if new is not None:
            stream.set_data(new)
            if NameObject("/Length1") in stream:
                stream[NameObject("/Length1")] = type(stream["/Length1"])(len(new))
            fixed.append(str(obj.get("/FontName")))
    if fixed:
        tmp = path + ".tmp"
        with open(tmp, "wb") as fh:
            writer.write(fh)
        os.replace(tmp, path)
    return fixed


def main(paths):
    for p in paths:
        if not p.lower().endswith(".pdf") or not os.path.exists(p):
            continue
        fixed = fix_pdf(p)
        print(f"{os.path.basename(p)}: repaired {len(fixed)} font(s)" + (f" ({', '.join(fixed)})" if fixed else ""))


if __name__ == "__main__":
    files = sys.argv[1:] or os.environ.get("QUARTO_PROJECT_OUTPUT_FILES", "").split("\n")
    main([f for f in files if f])
