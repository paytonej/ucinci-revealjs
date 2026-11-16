-- pdf-image-width.lua
-- Lets an image carry a separate size for LaTeX output, e.g.
--   ![](photo.jpg){width="850px" pdf-width="60%"}
-- For latex/beamer, `pdf-width` replaces `width` (and drops `height` so the
-- aspect ratio is kept). For every other format the attribute is removed,
-- so slides keep their pixel sizes.
--
-- Code cells can do the same with cell options, e.g.
--   #| pdf-width: 3.4in
--   #| classes: wrap-right
-- For latex/beamer, the width and any wrap-left/wrap-right class are copied
-- onto the cell's output image(s), so fwrappe can turn a captioned figure
-- into a wrapfigure (fwrappe must run at post-render to see the figure).

function Div(div)
  local pdf_width = div.attributes["pdf-width"]
  if pdf_width == nil or not div.classes:includes("cell") then
    return nil
  end
  div.attributes["pdf-width"] = nil
  if not (FORMAT:match("latex") or FORMAT:match("beamer")) then
    return div
  end
  return div:walk({
    Image = function(img)
      img.attributes["width"] = pdf_width
      img.attributes["height"] = nil
      for _, cls in ipairs({ "wrap-left", "wrap-right" }) do
        if div.classes:includes(cls) and not img.classes:includes(cls) then
          img.classes:insert(cls)
        end
      end
      return img
    end
  })
end

function Image(img)
  local pdf_width = img.attributes["pdf-width"]
  if pdf_width == nil then
    return nil
  end
  img.attributes["pdf-width"] = nil
  if FORMAT:match("latex") or FORMAT:match("beamer") then
    img.attributes["width"] = pdf_width
    img.attributes["height"] = nil
  end
  return img
end
