-- ssus.lua — document filter for the ssus-slides revealjs format.
--
-- 1. Blueprint grounds. The title slide, every `# Section` slide, and any
--    `## Slide {.ssus-blueprint}` are painted blueprint with the graticule
--    grid through reveal's background layer (data-background-color and
--    data-background-gradient), which fills the screen at any aspect ratio
--    and survives PDF export. Painting the section element instead
--    letterboxed the hero on 16:10 screens. The class ssus-ground-blueprint
--    retunes the theme's custom properties for those slides. A header that
--    sets its own background-color or background-image keeps it.
-- 2. Parts and running heads. Each numbered `# Section` gets a sheet number
--    (data-ssus-part, "01"); each slide after it carries the part in its top
--    band (data-ssus-section, "01 · Name"). `{.unnumbered}` sections keep
--    the ground and the running head but take no number.
--    `ssus-running-head: false` turns both off.
-- 3. Dark decks. `ssus-dark: true` adds html.ssus-dark in a synchronous head
--    script, before first paint, and swaps the format's default corner mark
--    for its night twin in the DOM (Quarto injects .slide-logo after
--    filters run, so the swap cannot happen in metadata). A deck that names
--    its own logo keeps it. There is no prefers-color-scheme: a deck is shown
--    in a room and must not flip with a laptop setting.
-- 4. The hero lockup. ssus-lockup-src carries assets/ssus-horizontal-dark.svg
--    into the title-slide partial as a data URI, unless ssus-lockup: false.

local BLUEPRINT = "#0F3B5E"
-- Surface 05's grid (ssus-identity-mocks.html): plan white at 6%, 30 px
local GRID = "repeating-linear-gradient(0deg, rgba(248,249,247,.06) 0 1px, transparent 1px 30px), "
  .. "repeating-linear-gradient(90deg, rgba(248,249,247,.06) 0 1px, transparent 1px 30px)"

-- An SVG from the extension folder as a data URI, read at render time so
-- the embedded copy never drifts from the file. Inline, because a file src
-- breaks once a deck is copied away from its _extensions folder.
local function svg_data_uri(name)
  local f = io.open(quarto.utils.resolve_path(name), "r")
  if not f then return nil end
  local svg = f:read("a")
  f:close()
  svg = svg:gsub("%s+", " "):gsub("[%%#<>\"' ]", function(c)
    return string.format("%%%02X", c:byte())
  end)
  return "data:image/svg+xml," .. svg
end

local function has_own_background(attributes)
  return attributes["background-color"] or attributes["background-image"]
    or attributes["background-gradient"] or attributes["background-video"]
    or attributes["background-iframe"]
end

local function paint_blueprint(header)
  if has_own_background(header.attributes) then return end
  header.attributes["background-color"] = BLUEPRINT
  header.attributes["background-gradient"] = GRID
  header.classes:insert("ssus-ground-blueprint")
end

local function meta_true(value, default)
  if value == nil then return default end
  if type(value) == "boolean" then return value end
  return pandoc.utils.stringify(value) == "true"
end

local running_head = true

local function title_slide(meta)
  -- the hero rides the same background layer as the section slides
  local attrs = meta["title-slide-attributes"] or pandoc.MetaMap({})
  local own = false
  for key, _ in pairs(attrs) do
    if key:match("^data%-background") then own = true end
  end
  if not own then
    attrs["data-background-color"] = pandoc.MetaString(BLUEPRINT)
    attrs["data-background-gradient"] = pandoc.MetaString(GRID)
  end
  meta["title-slide-attributes"] = attrs
end

local function dark(meta)
  quarto.doc.include_text("in-header",
    '<script>document.documentElement.classList.add("ssus-dark")</script>')
  local night = svg_data_uri("ssus-mark-night.svg")
  if not night then return end
  quarto.doc.include_text("after-body", [[
<script>(function () {
  document.querySelectorAll("img.slide-logo").forEach(function (img) {
    if (/ssus-mark-light\.svg$/.test(img.getAttribute("src") || "")) {
      img.src = "]] .. night .. [[";
    }
  });
})();
</script>]])
end

local function Meta(meta)
  -- the title-slide partial renders the lockup unless ssus-lockup: false
  if meta["ssus-lockup"] == nil then meta["ssus-lockup"] = true end
  if meta_true(meta["ssus-lockup"], true) then
    local src = svg_data_uri("assets/ssus-horizontal-dark.svg")
    if src then meta["ssus-lockup-src"] = pandoc.MetaInlines({ pandoc.RawInline("html", src) }) end
  end
  running_head = meta_true(meta["ssus-running-head"], true)
  title_slide(meta)
  if meta_true(meta["ssus-dark"], false) then dark(meta) end
  return meta
end

local function Pandoc(doc)
  local part, section = 0, nil
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 1 then
      paint_blueprint(block)
      local name = pandoc.utils.stringify(block.content)
      if block.classes:includes("unnumbered") then
        section = name
      else
        part = part + 1
        local number = string.format("%02d", part)
        if running_head then block.attributes["data-ssus-part"] = number end
        section = number .. " · " .. name
      end
    elseif block.t == "Header" and block.level == 2 then
      if block.classes:includes("ssus-blueprint") then paint_blueprint(block) end
      if running_head and section and not block.attributes["data-ssus-section"] then
        block.attributes["data-ssus-section"] = section
      end
    end
  end
  return doc
end

return {
  { Meta = Meta },
  { Pandoc = Pandoc },
}
