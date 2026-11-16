-- Renders .objectives-box (Div), .bloom-<X> (Span), .module-<X> (Span), and
-- .learning-objective-number (Span) with LaTeX equivalents of the HTML/CSS
-- styling defined in custom.css, so that pdf and beamer output match the
-- html/revealjs appearance instead of rendering as unstyled plain text.

local BLOOM_COLORS = {
  R  = { bg = "E6F1FB", fg = "0C447C" },
  U  = { bg = "EAF3DE", fg = "27500A" },
  Ap = { bg = "FAEEDA", fg = "633806" },
  An = { bg = "EEEDFE", fg = "3C3489" },
  E  = { bg = "FAECE7", fg = "712B13" },
  C  = { bg = "FBEAF0", fg = "72243E" },
}

local MODULE_COLORS = {
  M1 = { bg = "E3ECF5", fg = "1F4E79" },
  M2 = { bg = "E6F4E7", fg = "2E7D32" },
  M3 = { bg = "ECE7F8", fg = "4527A0" },
  M4 = { bg = "FCEBDF", fg = "B84000" },
  M5 = { bg = "FBE7F0", fg = "880E4F" },
}

local OBJ_NUM_BG = "ECECEC"
local OBJ_NUM_FG = "444444"

local BOX_BG = "D6E4F0"
local BOX_BORDER = "1F4E79"

local function is_latex()
  return quarto.doc.is_format("pdf") or quarto.doc.is_format("beamer")
end

local function latex_escape(s)
  s = s:gsub("\\", "\\textbackslash{}")
  s = s:gsub("([#$%%&_{}])", "\\%1")
  return s
end

local function badge(bg, fg, text)
  return pandoc.RawInline("latex", string.format(
    "\\mbox{\\fboxsep=2pt\\colorbox[HTML]{%s}{\\textcolor[HTML]{%s}{\\scriptsize\\bfseries %s}}}",
    bg, fg, latex_escape(text)
  ))
end

function Pandoc(doc)
  if not is_latex() then
    return doc
  end

  quarto.doc.use_latex_package("xcolor")
  quarto.doc.use_latex_package("tcolorbox")
  quarto.doc.include_text("in-header", table.concat({
    "\\tcbuselibrary{skins,breakable}",
    string.format("\\definecolor{objboxbg}{HTML}{%s}", BOX_BG),
    string.format("\\definecolor{objboxborder}{HTML}{%s}", BOX_BORDER),
  }, "\n"))

  return doc:walk({
    Span = function (el)
      for _, cls in ipairs(el.classes) do
        if cls == "learning-objective-number" then
          return badge(OBJ_NUM_BG, OBJ_NUM_FG, pandoc.utils.stringify(el.content))
        end
        local level = cls:match("^bloom%-(.+)$")
        if level and BLOOM_COLORS[level] then
          local c = BLOOM_COLORS[level]
          return badge(c.bg, c.fg, pandoc.utils.stringify(el.content))
        end
        local mod = cls:match("^module%-(.+)$")
        if mod and MODULE_COLORS[mod] then
          local c = MODULE_COLORS[mod]
          return badge(c.bg, c.fg, pandoc.utils.stringify(el.content))
        end
      end
      return el
    end,
    Div = function (el)
      if not el.classes:includes("objectives-box") then
        return el
      end
      local open = pandoc.RawBlock("latex",
        "\\begin{tcolorbox}[enhanced, breakable, colback=objboxbg, colframe=objboxborder, boxrule=1pt, arc=2mm, left=6pt, right=6pt, top=4pt, bottom=4pt]"
      )
      local close = pandoc.RawBlock("latex", "\\end{tcolorbox}")
      local blocks = pandoc.List({ open })
      blocks:extend(el.content)
      blocks:insert(close)
      return blocks
    end
  })
end
