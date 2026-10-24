# Notice

**Vexari UI** is a modified version of **WindUI**.

## Original work

- Project: WindUI – https://github.com/Footagesus/WindUI
- Author: Footagesus (Footages)
- License: MIT, Copyright (c) 2026 Footages – see [LICENSE](LICENSE)

The MIT License requires that the copyright notice and the permission notice stay in all copies or substantial
portions of the software. Keep `LICENSE` and this file when you redistribute or fork Vexari UI.
If you add your own copyright line, add it **below** the existing one in `LICENSE`, never instead of it.

Vexari UI is an independent fork. It is not affiliated with, or endorsed by, the WindUI project.

## What Vexari UI changed

- Renamed the project and the visible texts to "Vexari UI" (the Lua API names were kept for compatibility)
- Added a built-in Settings tab (`Window:CreateSettingsTab`)
- Added a runtime background image system with separate Roblox-ID and image-URL sources (`Window:SetBackground`)
- Added the `Vexari`, `Vexari Light` and `Obsidian` themes and a font registry (`WindUI:GetFonts`, `WindUI:SetFont(name)`)
- Added dashboard components (live fps / ping line, profile card, stat cards, page header, tab indicator, `Style = "Dashboard"`)
- Fixed `Window:SetBackgroundImage` and made the font update cheaper
- Added logic tests in `tests/vexari/`

See [changelog.md](changelog.md) for details.

## Third-party content

The icon data bundled in `dist/main.lua` comes from https://github.com/Footagesus/Icons, which collects several icon
sets (see the list in the README). Those sets keep their own licenses. Check them before redistributing the icons
on their own or using them outside this library.
