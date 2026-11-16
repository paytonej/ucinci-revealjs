-- Makes raw \ce{...} chemistry notation (mhchem) work inside math mode.
-- Injected via a filter (rather than a per-document `format:` key) so the
-- document doesn't narrow its own render targets to just the formats listed.
--
-- pdf / beamer: adds the mhchem and mathtools LaTeX packages.
--
-- html / revealjs with KaTeX: pandoc's KaTeX loader fetches katex.min.js from
-- the CDN at DOMContentLoaded and renders every .math span when it loads, with
-- no hook for KaTeX extensions, so \ce comes out as a red error. Instead, load
-- KaTeX and its mhchem extension as ordinary <script> tags in the header (so
-- --embed-resources inlines them), then freeze window.katex so the loader's
-- second copy of KaTeX can't replace the one that knows \ce. The loader's
-- onload still fires and renders with ours. The version must match the
-- katex.min.css that pandoc links (0.13.11 for Quarto 1.x).
-- MathJax needs nothing: it loads mhchem on demand.

local KATEX = "https://cdn.jsdelivr.net/npm/katex@0.13.11/dist/"

local function is_latex()
  return quarto.doc.is_format("pdf") or quarto.doc.is_format("beamer")
end

local function uses_katex()
  local ok, method = pcall(function() return PANDOC_WRITER_OPTIONS.html_math_method end)
  if not ok or method == nil then return false end
  if type(method) == "table" then method = method.method end
  return tostring(method):lower() == "katex"
end

-- Only documents that use mhchem get the extra packages / scripts.
local function uses_mhchem(doc)
  local found = false
  doc:walk({
    Math = function(m)
      if m.text:find("\\ce%s*{") or m.text:find("\\pu%s*{") then found = true end
    end,
    RawInline = function(r)
      if r.text:find("\\ce%s*{") then found = true end
    end,
  })
  return found
end

function Pandoc(doc)
  -- The filter can be listed twice (the ucinci-revealjs format runs it, and a
  -- document or profile may too): include everything only once.
  if doc.meta["mhchem-header-done"] or not uses_mhchem(doc) then return nil end
  doc.meta["mhchem-header-done"] = true
  if is_latex() then
    quarto.doc.include_text("in-header", table.concat({
      "\\usepackage[version=4]{mhchem}",
      "\\usepackage{mathtools}",
    }, "\n"))
  elseif quarto.doc.is_format("html") and uses_katex() then
    quarto.doc.include_text("in-header", table.concat({
      '<script src="' .. KATEX .. 'katex.min.js"></script>',
      '<script src="' .. KATEX .. 'contrib/mhchem.min.js"></script>',
      "<script>",
      "  var d = Object.getOwnPropertyDescriptor(window, 'katex');",
      "  if (window.katex && !(d && d.writable === false)) {",
      "    Object.defineProperty(window, 'katex', { value: window.katex, writable: false, configurable: false });",
      "  }",
      "</script>",
    }, "\n"))
  end
  return doc
end
