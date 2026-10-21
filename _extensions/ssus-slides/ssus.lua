-- ssus.lua — document filter for the ssus-slides revealjs format.
--
-- One job, driven by `ssus-dark: true`: dark-deck support. There is no
-- prefers-color-scheme anywhere: decks are shared-room artifacts and must
-- not flip mid-presentation.
--
--   1. An ssus-dark class on <html>, added via a synchronous head script.
--      SCSS variables are compile-time, so the opt-in dark theme flips CSS
--      custom properties at runtime on this class (see ssus-slides.scss).
--      The class lands before first paint and works for decks without a
--      title slide.
--   2. A script at the end of body that swaps the format's default
--      content-slide mark (ssus-mark-light.svg) for its night variant.
--      Quarto injects the .slide-logo <img> itself, after document filters
--      run, so a metadata rewrite here would never reach it — the swap has
--      to happen in the DOM. Only the sentinel filename is touched: a deck
--      that set its own logo keeps it.

local function ssus_dark(meta)
  -- ssus-lockup defaults to true; the title-slide partial renders the
  -- stacked lockup unless the deck suppresses it with ssus-lockup: false
  if meta["ssus-lockup"] == nil then meta["ssus-lockup"] = true end
  if not meta["ssus-dark"] then return meta end
  quarto.doc.include_text("in-header",
    '<script>document.documentElement.classList.add("ssus-dark")</script>')
  quarto.doc.include_text("after-body", [[
<script>(function () {
  document.querySelectorAll("img.slide-logo").forEach(function (img) {
    img.src = img.src.replace(/ssus-mark-light\.svg$/, "ssus-mark-night.svg");
  });
})();
</script>]])
  return meta
end

return {
  {
    Meta = function(meta) return ssus_dark(meta) end,
  },
}