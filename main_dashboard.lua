--[[
    Vexari UI | Dashboard example
    A Home page built from the dashboard components:
      * Window Config  Style = "Dashboard", Status = true      (tab indicator bar, CAPS group titles, fps / ms line)
      * OpenButton     Style = "Minimal"                        (dark pill with the fps / ms line)
      * Tab:Header / Tab:Profile / Tab:Stats                    (overview page)

    Load it with:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/vbcghhi-cell/WindUI/refs/heads/main/main_dashboard.lua"))()
]]

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/vbcghhi-cell/WindUI/main/dist/main.lua"))()

WindUI:SetTheme("Obsidian")

local Window = WindUI:CreateWindow({
    Title = "Star Hub",
    Folder = "starhub",
    Icon = "star",
    Size = UDim2.fromOffset(780, 520),
    SideBarWidth = 220,
    Style = "Dashboard", -- tab indicator bar + upper-case sidebar group titles
    Status = true,       -- "● 60 fps  ● 78 ms" under the title and on the open button
    OpenButton = {
        Style = "Minimal", -- near-black pill with a thin grey outline
        OnlyMobile = false,
    },
})

-- version chip next to the title
Window:Tag({
    Title = "v1.0.0",
    Color = Color3.fromHex("#2a2a30"),
    Border = true,
})

----------------------------------------------------------------------------------------------------
-- Home
----------------------------------------------------------------------------------------------------
local Home = Window:Tab({ Title = "Home", Icon = "home" })

Home:Header({
    Eyebrow = "Overview",
    Title = "Home",
    Icon = "home",
})

local Profile = Home:Profile({
    -- Title / Desc / Avatar default to the local player
    Button = {
        Title = "Lobby",
        Callback = function()
            WindUI:Notify({ Title = "Lobby", Content = "Button pressed" })
        end,
    },
    Status = { Text = "Waiting for a round", Icon = "hourglass" },
})

local Wallet = Home:Stats({
    Items = {
        { Key = "coins", Title = "Coins", Value = 1540, Color = "Yellow" },
        { Key = "gems", Title = "Gems", Value = 0, Color = "Blue" },
        { Key = "level", Title = "Level", Value = 100, Color = "Purple" },
    },
})

local Farm = Home:Stats({
    Items = {
        { Key = "state", Title = "Auto farm", Value = "ON", ValueColor = "Green" },
        { Key = "rate", Title = "Per hour", Value = "-", Color = "Green" },
        { Key = "collected", Title = "Collected", Value = 0, Color = "Orange" },
        { Key = "uptime", Title = "Uptime", Value = "0h 00m" },
    },
})

-- keep the numbers live (example)
local Started = os.clock()
task.spawn(function()
    while Window and not Window.Destroyed do
        task.wait(1)
        local Seconds = math.floor(os.clock() - Started)
        Farm:SetValue("uptime", string.format("%dh %02dm", Seconds // 3600, (Seconds % 3600) // 60))
    end
end)

Home:Section({
    Title = "Quick Actions",
    Icon = "zap",
    Box = true,
    Opened = true,
})

Home:Button({
    Title = "Collect rewards",
    Callback = function()
        Wallet:SetValue("coins", (Wallet:GetValue("coins") or 0) + 100)
        Profile:SetStatus("Rewards collected", "check", "Green")
    end,
})

----------------------------------------------------------------------------------------------------
-- Sidebar groups (shown as "PLAYER", "COMBAT" with the Dashboard style)
----------------------------------------------------------------------------------------------------
local Player = Window:Section({ Title = "Player", Icon = "user", Opened = true })
Player:Tab({ Title = "Movement", Icon = "footprints" })
Player:Tab({ Title = "Emotes", Icon = "smile" })
Player:Tab({ Title = "Players", Icon = "users" })

local Combat = Window:Section({ Title = "Combat", Icon = "swords", Opened = true })
Combat:Tab({ Title = "Aim", Icon = "crosshair" })

-- theme / font / transparency / background image
Window:CreateSettingsTab()
