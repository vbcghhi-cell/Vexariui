<img src="docs/WindUI – Themes.png" alt="Vexari UI Banner">

# Vexari UI

Vexari UI is a Roblox (Luau) UI library for script hubs. It is a **fork of [WindUI](https://github.com/Footagesus/WindUI)** by Footagesus (Footages, .ftgs) and keeps WindUI's API, so scripts written for WindUI keep working.

> [!NOTE]
> The banner image above is the original WindUI artwork and has not been replaced yet.

> [!WARNING]
> This project is in Beta. Bugs, issues and unstable features may occur.

## What Vexari UI adds

- **Settings tab** – `Window:CreateSettingsTab()` builds a ready-made tab with theme, font, window transparency and background image controls
- **Background image** – change the window background at runtime from an asset id / URL, with Apply and Reset, without recreating the window
- **Themes** – `Vexari` (dark) and `Vexari Light`
- **Fonts** – a font list built from fonts that ship with Roblox (`WindUI:GetFonts()`, `WindUI:SetFont(name)`)

## Installation

```luau
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/vbcghhi-cell/VexariUI/main/dist/main.lua"))()
```

Everything lives in this one repository: the source in `src/`, the icon packs in `src/Icons/` and the ready-to-use bundle in `dist/main.lua`. Loading the library does not fetch anything from any other repository.

(Change the URL if you host the repository under another name or branch.)

## Quick start

```luau
local Window = WindUI:CreateWindow({
    Title = "My Hub",
    Folder = "myhub",
})

local Tab = Window:Tab({ Title = "Main", Icon = "home" })
Tab:Button({
    Title = "Hello",
    Callback = function()
        WindUI:Notify({ Title = "Vexari UI", Content = "It works!" })
    end,
})

-- Built-in Settings tab (theme, font, transparency, background image)
Window:CreateSettingsTab()
```

### Background image API

```luau
-- source: asset id (number or string), "rbxassetid://id", a roblox.com asset link,
--         or an http(s) image URL (executors with writefile + getcustomasset only)
-- Yields until the image is loaded. Returns true, or false + an error message.
local ok, err = Window:SetBackground("123456789", {
    Transparency = 0.35,   -- 0 = fully visible image, 1 = invisible
    ScaleType = "Crop",    -- "Crop" (fill) | "Fit" | "Stretch"
})
if not ok then
    warn(err)
end

Window:SetBackgroundImageTransparency(0.5) -- existing API, now also controls the custom image
Window:SetBackgroundScaleType("Fit")
print(Window:GetBackground().Active)
Window:ResetBackground()                   -- back to the window's original background
```

Use the **Image** asset id, not the Decal id. If a Decal id is entered, Vexari UI tries to resolve the image id behind it on executors that support `game:GetObjects`, otherwise it reports that the asset is not a displayable image.

### Fonts and themes

```luau
print(table.concat(WindUI:GetFonts(), ", "))   -- Default, Gotham, Source Sans, ...
WindUI:SetFont("Gotham")                       -- registered name or a raw font family / asset id
WindUI:SetTheme("Vexari")
```

## Project layout

| Path | Purpose |
| --- | --- |
| `src/` | Library source (Luau). `src/Init.lua` is the entry point |
| `src/Icons/` | Icon packs (lucide, solar, craft, geist, sfsymbols, gravity) and the icon registry, vendored from [Footagesus/Icons](https://github.com/Footagesus/Icons) (MIT) |
| `src/components/window/Background.lua` | Background image manager (new) |
| `src/components/window/Settings.lua` | Built-in Settings tab (new) |
| `src/modules/Fonts.lua` | Font registry (new) |
| `build/` | Build scripts and config (`npm run build`, uses darklua) |
| `dist/main.lua` | Bundled library that `loadstring` loads (generated, committed by CI) |
| `main.client.lua` | Full example |
| `tests/vexari/` | Logic tests for the Vexari additions (`npm test`, mocked Roblox API) |

## Building

Everything needed is in this repository, there are no submodules.

```sh
git clone https://github.com/vbcghhi-cell/VexariUI
cd VexariUI
npm install
aftman install   # installs rojo, lune and darklua (only darklua is needed for the build)
npm run build    # production build  -> dist/main.lua
npm run dev      # development build
npm test         # logic tests (needs Python 3 and liblua5.4, e.g. `apt install liblua5.4-0`)
```

Pushing to `main` rebuilds `dist/main.lua` through GitHub Actions. Pushing a tag creates a release.

## Contributing

Issues and pull requests are welcome. Every pull request is built automatically and the result is commented on the PR. Please run `npm test` and `npm run build` before opening one.

## Credits and license

- Vexari UI is based on **WindUI** by Footagesus – https://github.com/Footagesus/WindUI
- Licensed under the MIT License, see [LICENSE](LICENSE). The original copyright notice is kept.
- The icon registry and packs in `src/Icons/` come from https://github.com/Footagesus/Icons (MIT, see [src/Icons/LICENSE](src/Icons/LICENSE)).

#### Icon sources

- [Lucide-Icons](https://github.com/lucide-icons/lucide)
- [Craft Icons](https://www.figma.com/community/file/1415718327120418204)
- [Geist Icons](https://vercel.com/geist/icons)
- [Solar Icons](https://icones.js.org/collection/solar)
- [SF Symbols](https://sf-symbols-one.vercel.app/)
- [Gravity UI Icons](https://gravity-ui.com/icons)

The icon sets keep the licenses of their original authors. Check them before you redistribute the icons outside this project.

### Upstream links (WindUI)

- [Discord Server](https://discord.gg/ftgs-development-hub-1300692552005189632)
- [Documentation](https://footagesus.github.io/treehub-web/docs/windui) – the element API (Button, Toggle, Slider, ...) is unchanged
- [Installation](https://footagesus.github.io/WindUI-Docs/docs/installation)
