# 1.7.1

## Changelog (Vexari UI)

- merged the source repository and the `dist`-only repository into a single repository: sources, icon packs and the built `dist/main.lua` now live together
- icon packs are vendored in `src/Icons/` (no more git submodule) and are always loaded from the bundle; the library no longer downloads icons from another repository when it starts
- removed the unused Studio-only server scripts and the legacy `modules/Icons.lua`
- CI no longer needs submodules or an extra clone step; the repository URL is now `vbcghhi-cell/VexariUI`
- added `npm test`

# 1.7.0

## Changelog (Vexari UI)

- renamed the project to **Vexari UI** (fork of [WindUI](https://github.com/Footagesus/WindUI) by Footagesus, MIT). Public Lua API names are unchanged, existing scripts keep working
- added `Window:CreateSettingsTab(config)` – ready-made Settings tab (theme, font, window transparency, background image with Apply / Reset)
- added background image API: `Window:SetBackground(source, { Transparency, ScaleType })`, `Window:ResetBackground()`, `Window:SetBackgroundScaleType(name)`, `Window:GetBackground()`
  - accepts asset id, `rbxassetid://id`, `roblox.com` asset links and (on executors with `writefile` + `getcustomasset`) image URLs
  - validates input, checks that the asset really loads, reports errors instead of silently showing nothing, never creates a second `ImageLabel`
- fixed `Window:SetBackgroundImage()` erroring when the window was created without `Background`; it now goes through the validated path above
- added themes `Vexari` and `Vexari Light`
- added font registry: `WindUI:GetFonts()`, `WindUI:GetCurrentFont()`, `WindUI:AddFont(name, family)`; `WindUI:SetFont()` now accepts a font name as well as a raw family / asset id and returns `true` when applied
- `Creator.AddFontObject` no longer re-applies the font to every existing object (was O(n²) while building the UI); `Creator.UpdateFont` skips objects that fail instead of aborting
- ScreenGui names are now `VexariUI`, `VexariUI/Notifications`, `VexariUI/Dropdowns`, `VexariUI/Tooltips` (config / asset folders on disk are still `WindUI/...` so saved configs keep loading)

## WindUI 1.6.66 (upstream)

## Changelog

- added `CodeSize: number`, `CodeTheme: table`, `CanCopied: boolean` and `Height: UDim` to [Code](https://footagesus.github.io/treehub-web/docs/windui/code) element (#91)
- changed PandaDev API url in [Key System](https://footagesus.github.io/treehub-web/docs/windui/keysystem) (#92)
- fixed [Section](https://footagesus.github.io/treehub-web/docs/windui/sections) bg (in custom themes)
- fixed [Colorpicker](https://footagesus.github.io/treehub-web/docs/windui/colorpicker) issue
- fixed `Viewport` bug when u can pinch it outside
- fixed [Window](https://footagesus.github.io/treehub-web/docs/windui/window) Drag with multiple fingers (#79)
- added `ProgressBar` element (#95 by [BitRevenant](https://github.com/BitRevenant)) [Github PR](https://github.com/Footagesus/WindUI/pull/95)
- fixed `Dropdown.Locked` (#94 by [BitRevenant](https://github.com/BitRevenant)) [Github PR](https://github.com/Footagesus/WindUI/pull/94)
