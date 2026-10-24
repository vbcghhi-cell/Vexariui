# 1.7.0

## Changelog (Vexari UI)

- **dashboard look** (inspired by hub-style overview pages)
  - new components in `src/components/ui/`: `Status` (live fps / ping), `Chip`, `StatCard`, `ProfileCard`, `PageHeader`
  - new elements: `Tab:Header`, `Tab:Profile`, `Tab:Stats`
  - window Config `Status = true`: "● 60 fps  ● 78 ms" under the title and on the open button (`Window:SetStatus`)
  - window Config `Style = "Dashboard"`: left indicator bar on the selected tab and upper-case sidebar group titles (`TabIndicator`, `UppercaseSections` can be set one by one)
  - `OpenButton = { Style = "Minimal" }`: near-black pill with a thin grey outline
  - theme `Obsidian`
  - example: `main_dashboard.lua`

- renamed the project to **Vexari UI** (fork of [WindUI](https://github.com/Footagesus/WindUI) by Footagesus, MIT). Public Lua API names are unchanged, existing scripts keep working
- added `Window:CreateSettingsTab(config)` – ready-made Settings tab (theme, font, window transparency, background image with Apply / Reset)
- Settings background has two separate sources: a **Roblox image ID** box and an **Image URL** box (each with its own Apply button, one shared Reset). `Window:SetBackground(source, { Only = "id" | "url" })` restricts what is accepted
- image links: downloaded files no longer go through `ContentProvider:PreloadAsync` / strict `IsLoaded` checks (unreliable for executor custom assets); both `game:HttpGet` and `request()` are tried; web-page links, GIF and oversized files give a clear message; `imgur.com/<id>`, `github.com/.../blob/...` and Discord WebP links are converted to direct image links; failures are also printed with `warn`
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
