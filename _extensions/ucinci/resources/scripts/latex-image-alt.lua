-- latex-image-alt.lua
-- For PDF (LaTeX) output, pass an image's description to the tagged PDF:
--   ![](diagram.png){width=60% fig-alt="Cu-Ni phase diagram, 700 to 1500 C ..."}
-- becomes \includegraphics[width=0.6\linewidth, ..., alt={...}]{diagram.png}.
-- Quarto drops fig-alt for LaTeX output, so without this LaTeX's tagging uses the
-- file name as the image's description, which accessibility checkers report as
-- "images without a description". Images without fig-alt are left alone.

local function latex_escape(s)
  local map = {
    ["\\"] = "\\textbackslash{}", ["{"] = "\\{", ["}"] = "\\}", ["%"] = "\\%",
    ["#"] = "\\#", ["&"] = "\\&", ["_"] = "\\_", ["$"] = "\\$",
    ["~"] = "\\textasciitilde{}", ["^"] = "\\textasciicircum{}",
  }
  return (s:gsub("[\\{}%%#&_%$~%^]", map))
end

-- a Pandoc/Quarto size ("40%", "3in", "300px") as a LaTeX length
local function latex_size(value, relative_to)
  local pct = value:match("^([%d%.]+)%%$")
  if pct then
    return string.format("%g", tonumber(pct) / 100) .. relative_to
  end
  local px = value:match("^([%d%.]+)px$")
  if px then
    return string.format("%gin", tonumber(px) / 96)
  end
  local num = value:match("^([%d%.]+)$")
  if num then
    return string.format("%gin", tonumber(num) / 96)
  end
  return value
end

function Image(img)
  if not quarto.doc.is_format("latex") then
    return nil
  end
  local alt = img.attributes["fig-alt"]
  if alt == nil or alt == "" then
    return nil
  end
  local opts = {}
  local width, height = img.attributes["width"], img.attributes["height"]
  if width then
    table.insert(opts, "width=" .. latex_size(width, "\\linewidth"))
  end
  if height then
    table.insert(opts, "height=" .. latex_size(height, "\\textheight"))
  elseif width then
    table.insert(opts, "height=\\textheight")
  end
  table.insert(opts, "keepaspectratio")
  table.insert(opts, "alt={" .. latex_escape(alt) .. "}")
  local graphic = "\\includegraphics[" .. table.concat(opts, ",") .. "]{" .. img.src .. "}"
  if not width and not height then
    -- as Pandoc does for an image without a size: no larger than the page
    graphic = "\\pandocbounded{" .. graphic .. "}"
  end
  return pandoc.RawInline("latex", graphic)
end
