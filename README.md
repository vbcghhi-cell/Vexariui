<img src="docs/WindUI – Themes.png" alt="Vexari UI Banner">

# Vexari UI

Vexari UI is a Roblox (Luau) UI library for script hubs. It is a **fork of [WindUI](https://github.com/Footagesus/WindUI)** by Footagesus (Footages, .ftgs) and keeps WindUI's API, so scripts written for WindUI keep working.

> [!NOTE]
> The banner image above is the original WindUI artwork and has not been replaced yet.

> [!WARNING]
> This project is in Beta. Bugs, issues and unstable features may occur.

## What Vexari UI adds

- **Settings tab** – `Window:CreateSettingsTab()` builds a ready-made tab with theme, font, window transparency and background image controls
- **Background image** – change the window background at runtime from a Roblox image ID **or** an image URL (separate boxes, Apply and Reset), without recreating the window
- **Dashboard components** – live fps / ping line, profile card, stat cards, page header (see "Dashboard look")
- **Themes** – `Vexari` (dark), `Vexari Light` and `Obsidian` (neutral near-black)
- **Fonts** – a font list built from fonts that ship with Roblox (`WindUI:GetFonts()`, `WindUI:SetFont(name)`)

## Dashboard look

```luau
local Window = WindUI:CreateWindow({
    Title = "Star Hub",
    Style = "Dashboard",                       -- indicator bar on the selected tab, CAPS group titles
    Status = true,                             -- "● 60 fps  ● 78 ms" under the title and on the open button
    OpenButton = { Style = "Minimal", OnlyMobile = false },
})
WindUI:SetTheme("Obsidian")

local Home = Window:Tab({ Title = "Home", Icon = "home" })
Home:Header({ Eyebrow = "Overview", Title = "Home", Icon = "home" })
Home:Profile({                                  -- name / @username / avatar default to the local player
    Button = { Title = "Lobby", Callback = function() end },
    Status = { Text = "Waiting for a round", Icon = "hourglass" },
})
local Stats = Home:Stats({
    Items = {
        { Key = "coins", Title = "Coins", Value = 1540, Color = "Yellow" },  -- Color = label color
        { Key = "farm", Title = "Auto farm", Value = "ON", ValueColor = "Green" },
    },
})
Stats:SetValue("coins", 2500)                   -- numbers get thousands separators: "2,500"
```

Colors accept a `Color3`, `"#rrggbb"` or a name (`Yellow Blue Purple Green Orange Red Pink Cyan White Gray`).
`Window:SetStatus(false)` removes the fps / ms line, `Window:SetStatus({ Ping = false })` shows fps only.
The full page is in `main_dashboard.lua`.

## Installation

```luau
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/vbcghhi-cell/WindUI/main/dist/main.lua"))()
```

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
-- A successful call may return a second value: a warning to show to the user.
local ok, message = Window:SetBackground("123456789", {
    Transparency = 0.35,   -- 0 = fully visible image, 1 = invisible
    ScaleType = "Crop",    -- "Crop" (fill) | "Fit" | "Stretch"
    Only = "id",           -- optional: "id" = Roblox asset ids only, "url" = links only
})
if not ok then
    warn(message)
end

-- image from a link (PNG / JPEG, direct link)
Window:SetBackground("https://i.imgur.com/xxxxxxx.png", { Only = "url" })

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
| `src/components/window/Background.lua` | Background image manager (new) |
| `src/components/window/Settings.lua` | Built-in Settings tab (new) |
| `src/modules/Fonts.lua` | Font registry (new) |
| `src/components/ui/` | `Status`, `Chip`, `StatCard`, `ProfileCard`, `PageHeader` (new, dashboard components) |
| `src/elements/` | `Header`, `Profile`, `Stats` elements (new) |
| `build/` | Build scripts and config (`npm run build`, uses darklua + Rojo) |
| `dist/main.lua` | Bundled library that `loadstring` loads |
| `main.client.lua` | Full example |
| `main_dashboard.lua` | Dashboard-style example (Home page with profile + stat cards) |
| `tests/vexari/` | Logic tests for the Vexari additions (`python3 tests/vexari/run_tests.py`, mocked Roblox API) |

## Building

`src/Icons` is a git submodule (`Footagesus/Icons`). Clone with `git clone --recursive`, or run `git submodule update --init`, then:

```sh
npm install
aftman install   # installs rojo, lune and darklua
npm run build    # production build  -> dist/main.lua
npm run dev      # development build
```

## Credits and license

- Vexari UI is based on **WindUI** by Footagesus – https://github.com/Footagesus/WindUI
- Licensed under the MIT License, see [LICENSE](LICENSE). The original copyright notice is kept.
- See [NOTICE.md](NOTICE.md) for the attribution and the list of changes.

#### Icons (https://github.com/Footagesus/Icons)

- [Lucide-Icons](https://github.com/lucide-icons/lucide)
- [Craft Icons](https://www.figma.com/community/file/1415718327120418204)
- [Geist Icons](https://vercel.com/geist/icons)
- [Solar Icons](https://icones.js.org/collection/solar)
- [SF Symbols](https://sf-symbols-one.vercel.app/)

## Contributing

- Run the logic tests before opening a pull request: `python3 tests/vexari/run_tests.py` (Linux, needs `liblua5.4`)
- Build with `npm run build` (see "Building"). Pull requests are built automatically by GitHub Actions
- Keep `LICENSE` and `NOTICE.md` intact

### Upstream links (WindUI)

- [Discord Server](https://discord.gg/ftgs-development-hub-1300692552005189632)
- [Documentation](https://footagesus.github.io/treehub-web/docs/windui) – the element API (Button, Toggle, Slider, ...) is unchanged
- [Installation](https://footagesus.github.io/WindUI-Docs/docs/installation)
