-- poll.lua
-- Write a live poll (the `poll` revealjs plugin) as plain markdown:
--
--   ::: {.poll}
--   Which particle melts at the lower temperature?
--
--   - [x] The 5 nm particle
--   - [ ] The 50 nm particle
--   - [ ] Both melt at 1064$^\circ$C
--   :::
--
-- Everything before the list is the question; each list item is an answer.
-- Mark correct answers with [x] (more than one is allowed); [ ] or no box
-- means wrong. Math and other markdown work in the question and answers.
--
-- Where the box sits on the slide:
--   position="center"        (default) centered on the slide
--   position="bottom-left"   lower-left corner, clear of a right-hand figure
--   position="bottom-right"  lower-right corner
--   style="..."              any other CSS placement (overrides position)
--
-- Time limit: the poll closes and shows its results after 30 s, or as soon as
-- the presenter advances the slide (or clicks an answer), whichever is first.
--   time=45                  a different limit in seconds; time=0 = no timer
--
-- revealjs: emits the <div class="poll fragment"> markup the plugin expects;
--           the poll opens when the box appears and closes (showing the
--           results) when its time runs out, the presenter advances, or an
--           answer is clicked.
-- other formats (pdf, html, beamer): the question in bold with lettered
--           answers, none marked correct.
--
-- Poll server and key: a revealjs deck with a poll gets both in a header
-- <script> as window.RevealPollConfig; other formats (Canvas pages,
-- handouts) never receive them.
--   poll-server: https://example.edu/~you/poll   (document or project metadata)
--   "poll_key": "..."   in the project's _secrets.json (keep it out of git);
--                        must match $SECRET_KEY in pollapi/index.php.

local POSITIONS = {
  ["center"]       = "top:50%; left:50%; right:auto; bottom:auto; transform:translate(-50%, -50%);",
  ["bottom-left"]  = "bottom:50px; left:50px; right:auto",
  ["bottom-right"] = "bottom:50px",
}

local CHECKED, UNCHECKED = "\u{2612}", "\u{2610}"   -- what pandoc makes of [x] and [ ]

-- The voting page shows whatever HTML the slide sends. KaTeX markup is unreadable
-- there (no KaTeX CSS), so each question and answer also carries a copy with math
-- as MathML, which browsers draw natively; poll.js sends that copy.
local function vote_html(inlines)
  local html = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "html",
                            { html_math_method = "mathml", wrap_text = "none" })
  html = html:gsub("^%s+", ""):gsub("%s+$", "")
  return (html:gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

-- Strip the task-list box from an item; return its inlines and whether it was [x].
local function parse_answer(item)
  local inlines = pandoc.Inlines({})
  for _, blk in ipairs(item) do
    if blk.t == "Plain" or blk.t == "Para" then
      if #inlines > 0 then inlines:insert(pandoc.Space()) end
      inlines:extend(blk.content)
    end
  end
  local correct = false
  local first = inlines[1]
  if first and first.t == "Str" and (first.text == CHECKED or first.text == UNCHECKED) then
    correct = first.text == CHECKED
    inlines:remove(1)
    if inlines[1] and inlines[1].t == "Space" then inlines:remove(1) end
  end
  return inlines, correct
end

-- Split the div into question inlines and the first bullet list (searching
-- inside wrapper divs, e.g. one added by slide-nonincremental.lua).
local function split(div)
  local question, list = pandoc.Inlines({}), nil
  local function scan(blocks)
    for _, blk in ipairs(blocks) do
      if list then return end
      if blk.t == "BulletList" or blk.t == "OrderedList" then
        list = blk
      elseif blk.t == "Div" then
        scan(blk.content)
      elseif blk.t == "Para" or blk.t == "Plain" then
        if #question > 0 then question:insert(pandoc.Space()) end
        question:extend(blk.content)
      end
    end
  end
  scan(div.content)
  return question, list
end

local has_poll = false

-- The poll key from <project>/_secrets.json, or nil (with a warning).
local function read_poll_key()
  local dir = (quarto.project and quarto.project.directory) or "."
  local path = pandoc.path.join({ dir, "_secrets.json" })
  local f = io.open(path, "r")
  if not f then
    io.stderr:write("poll.lua: " .. path .. " not found; live polls will not open\n")
    return nil
  end
  local text = f:read("a")
  f:close()
  local ok, secrets = pcall(quarto.json.decode, text)
  local key = ok and type(secrets) == "table" and secrets["poll_key"] or nil
  if type(key) ~= "string" or key == "" then
    io.stderr:write("poll.lua: no \"poll_key\" in " .. path .. "; live polls will not open\n")
    return nil
  end
  return key
end

-- A JavaScript string literal: JSON-encoded, with "</" broken up so it can't
-- close the <script> tag.
local function js_string(s)
  return (quarto.json.encode(s):gsub("</", "<\\/"))
end

function Pandoc(doc)
  if not (has_poll and FORMAT:match("revealjs")) then return nil end
  local url = doc.meta["poll-server"] and pandoc.utils.stringify(doc.meta["poll-server"]) or ""
  if url == "" then
    io.stderr:write("poll.lua: no poll-server: in the metadata; live polls will not open\n")
  end
  local key = read_poll_key() or ""
  quarto.doc.include_text("in-header", "<script>window.RevealPollConfig = { url: "
    .. js_string(url) .. ", key: " .. js_string(key) .. " };</script>")
  return nil
end

function Div(div)
  if not div.classes:includes("poll") then return nil end
  has_poll = true
  local question, list = split(div)
  if not list then
    -- Older polls written as raw HTML (<h1>, <ul>, <li>) also arrive here as a
    -- .poll div; leave those alone and warn only about a real authoring slip.
    local legacy = false
    div:walk({ RawBlock = function() legacy = true end })
    if not legacy then
      io.stderr:write("poll.lua: a .poll div has no answer list; left unchanged\n")
    end
    return nil
  end

  local answers = {}
  for _, item in ipairs(list.content) do
    local inlines, correct = parse_answer(item)
    table.insert(answers, { inlines = inlines, correct = correct })
  end

  if FORMAT:match("revealjs") then
    local style = div.attributes["style"]
      or POSITIONS[div.attributes["position"] or "center"]
      or POSITIONS["center"]
    local blocks = pandoc.Blocks({
      pandoc.RawBlock("html", '<h1 data-poll-html="' .. vote_html(question) .. '">'),
      pandoc.Plain(question), pandoc.RawBlock("html", "</h1>"),
      pandoc.RawBlock("html", "<ul>"),
    })
    for _, a in ipairs(answers) do
      blocks:insert(pandoc.RawBlock("html", "<li" .. (a.correct and ' data-poll="correct"' or "")
        .. ' data-poll-html="' .. vote_html(a.inlines) .. '">'))
      blocks:insert(pandoc.Plain(a.inlines))
      blocks:insert(pandoc.RawBlock("html", "</li>"))
    end
    blocks:insert(pandoc.RawBlock("html", "</ul>\n<h2></h2>"))
    local attrs = { style = style }
    if div.attributes["time"] then attrs["data-poll-time"] = div.attributes["time"] end
    return pandoc.Div(blocks, pandoc.Attr("", { "poll", "fragment" }, attrs))
  end

  local items = {}
  for _, a in ipairs(answers) do
    table.insert(items, { pandoc.Plain(a.inlines) })
  end
  return pandoc.Div({
    pandoc.Para({ pandoc.Strong(question) }),
    pandoc.OrderedList(items, pandoc.ListAttributes(1, "UpperAlpha", "Period")),
  }, pandoc.Attr("", { "poll-question" }))
end
