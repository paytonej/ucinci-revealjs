-- instructor-notes.lua
-- Two kinds of notes:
--
--   ::: {.notes}               rendered in every profile, as before (speaker
--   ...                        notes in the slides; text in the PDFs, Canvas
--   :::                        pages, and handouts)
--
--   ::: {.instructor-notes}    rendered ONLY in the instructor printout: the
--   ...                        PDF of the lecture profile, where it appears as
--   :::                        a boxed "Instructor notes" callout. Removed from
--                              everything students can open: the slides
--                              (including the speaker notes, which anyone with
--                              the HTML can show with S), Canvas pages and
--                              quizzes, and handouts.
--
-- The lecture profile turns it on with `instructor-notes: true` under
-- `format: pdf:` in _quarto-lecture.yml. The filter must be listed in every
-- profile, so that the notes are removed where they are not turned on.

local show = false

local function truthy(v)
  if v == nil then return false end
  if type(v) == "boolean" then return v end
  local s = pandoc.utils.stringify(v):lower()
  return s == "true" or s == "yes" or s == "1"
end

local function Meta(meta)
  show = truthy(meta["instructor-notes"]) and FORMAT == "latex"
end

local function Div(div)
  if not div.classes:includes("instructor-notes") then return nil end
  if not show then return {} end
  return quarto.Callout({
    type = "important",
    title = "Instructor notes",
    content = div.content,
    appearance = "simple",
  })
end

return {
  { Meta = Meta },
  { Div = Div },
}
