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
--    (--ssus-part, "01"); each slide after it carries the part in its top
--    band (--ssus-section, "01 · Name"). `{.unnumbered}` sections keep
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
-- 5. The viewer's switch. `ssus-theme-toggle: true` adds a light/dark button
--    beside the menu button and the key T. The deck opens as rendered
--    (`ssus-dark`), never by the system setting, so a presenter's laptop
--    cannot flip it; a viewer's choice is kept in localStorage under
--    `ssus-theme`, the key name the lab site uses (storage is per site, so
--    the two never share a choice), and applied in the head before first
--    paint. Other windows of the same deck (the speaker view) follow it.
--    Only the page switches: a transparent figure drawn with one figure
--    style keeps its inks, so a toggled deck sets figures on .ssus-plate.

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

local function dark()
  quarto.doc.include_text("in-header",
    '<script>document.documentElement.classList.add("ssus-dark")</script>')
end

-- The saved choice, applied in the head after any `ssus-dark` class, so the
-- first paint is already the viewer's theme.
local function saved_theme()
  quarto.doc.include_text("in-header", [[
<script>(function () {
  try {
    var t = localStorage.getItem("ssus-theme");
    if (t === "dark" || t === "light") {
      document.documentElement.classList.toggle("ssus-dark", t === "dark");
    }
  } catch (e) {}
})();
</script>]])
end

-- The website's icons (ssus-website layouts/_default/baseof.html): the moon
-- offers dark from a light page, the sun light from a dark one.
local MOON = '<svg class="when-light" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/></svg>'
local SUN = '<svg class="when-dark" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/></svg>'

-- The corner mark follows html.ssus-dark: the night twin on a dark page, the
-- format's light mark otherwise. With the toggle, the same script builds the
-- button, binds T, and listens for the choice made in another window.
local function theme_script(toggle)
  local night = svg_data_uri("ssus-mark-night.svg") or ""
  local js = [[
<script>(function () {
  var root = document.documentElement;
  var NIGHT = "]] .. night .. [[";
  var marks = [].filter.call(document.querySelectorAll("img.slide-logo"), function (img) {
    return /ssus-mark-light\.svg$/.test(img.getAttribute("src") || "");
  });
  marks.forEach(function (img) { img.dataset.ssusLight = img.getAttribute("src"); });
  function isDark() { return root.classList.contains("ssus-dark"); }
  function mark() {
    if (!NIGHT) return;
    marks.forEach(function (img) { img.src = isDark() ? NIGHT : img.dataset.ssusLight; });
  }
  mark();
]]
  if toggle then
    js = js .. [[
  var btn = document.createElement("button");
  btn.type = "button";
  btn.className = "ssus-theme-toggle";
  btn.innerHTML = ']] .. MOON .. SUN .. [[';
  function label() {
    var text = isDark() ? "Switch to light theme (T)" : "Switch to dark theme (T)";
    btn.setAttribute("aria-label", text);
    btn.title = text;
  }
  function set(theme, save) {
    root.classList.toggle("ssus-dark", theme === "dark");
    mark();
    label();
    if (save) { try { localStorage.setItem("ssus-theme", theme); } catch (e) {} }
  }
  function flip() { set(isDark() ? "light" : "dark", true); }
  btn.addEventListener("click", function () { flip(); btn.blur(); });
  label();
  (document.querySelector(".reveal") || document.body).appendChild(btn);
  window.addEventListener("storage", function (e) {
    if (e.key === "ssus-theme" && (e.newValue === "dark" || e.newValue === "light")) {
      set(e.newValue, false);
    }
  });
  function bind() {
    Reveal.addKeyBinding({ keyCode: 84, key: "T", description: "Switch light and dark" }, flip);
  }
  if (window.Reveal) {
    if (Reveal.isReady && Reveal.isReady()) { bind(); } else { Reveal.on("ready", bind); }
  }
]]
  end
  quarto.doc.include_text("after-body", js .. "})();\n</script>")
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
  local is_dark = meta_true(meta["ssus-dark"], false)
  local toggle = meta_true(meta["ssus-theme-toggle"], false)
  if is_dark then dark() end
  if toggle then saved_theme() end
  if is_dark or toggle then theme_script(toggle) end
  return meta
end

-- The part number and the running head travel as CSS custom properties on
-- the section, read by the heading's ::before. Reveal's overview hides every
-- section's own ::before and ::after (display: none !important), so the
-- heading, not the section, has to draw them.
local function css_string(text)
  return '"' .. text:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function add_style(header, property, value)
  local style = header.attributes["style"]
  local decl = property .. ": " .. css_string(value)
  header.attributes["style"] = style and (style .. "; " .. decl) or decl
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
        if running_head then add_style(block, "--ssus-part", number) end
        section = number .. " · " .. name
      end
    elseif block.t == "Header" and block.level == 2 then
      if block.classes:includes("ssus-blueprint") then paint_blueprint(block) end
      if running_head and section then add_style(block, "--ssus-section", section) end
    end
  end
  return doc
end

return {
  { Meta = Meta },
  { Pandoc = Pandoc },
}
