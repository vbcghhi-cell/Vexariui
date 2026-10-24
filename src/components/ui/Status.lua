--[[
	Vexari UI | live FPS / ping status

	  Status.NewRow({ Parent = frame })  builds the small "● 55 fps  ● 130 ms" row used in the window
	                                     topbar and on the floating open button.
	  Status.Subscribe(function(fps, ping) end)  shared sampler, runs only while someone is subscribed.
	  Status.Rate("FPS" | "Ping", value)         "Good" | "Ok" | "Bad" (decides the dot color).

	FPS is measured from Heartbeat, ping from Stats > Network > ServerStatsItem["Data Ping"]
	(falls back to Player:GetNetworkPing, which is only approximate).
]]

local Creator = require("../../modules/Creator")
local New = Creator.New

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local RunService = cloneref(game:GetService("RunService"))
local Players = cloneref(game:GetService("Players"))

local Status = {
	Colors = {
		Good = Color3.fromHex("#34d399"),
		Ok = Color3.fromHex("#fbbf24"),
		Bad = Color3.fromHex("#f87171"),
		Unknown = Color3.fromHex("#9ca3af"),
	},
	-- FPS: higher is better. Ping: lower is better.
	Thresholds = {
		FPS = { Good = 50, Ok = 30 },
		Ping = { Good = 100, Ok = 200 },
	},
	SampleInterval = 0.5, -- seconds between updates
}

function Status.Rate(Kind, Value)
	if typeof(Value) ~= "number" or Value ~= Value then
		return "Unknown"
	end

	local Limits = Status.Thresholds[Kind]
	if not Limits then
		return "Unknown"
	end

	if Kind == "FPS" then
		if Value >= Limits.Good then
			return "Good"
		elseif Value >= Limits.Ok then
			return "Ok"
		end
		return "Bad"
	end

	if Value <= Limits.Good then
		return "Good"
	elseif Value <= Limits.Ok then
		return "Ok"
	end
	return "Bad"
end

----------------------------------------------------------------------------------------------------
-- Shared sampler
----------------------------------------------------------------------------------------------------

local Sampler = {
	Listeners = {},
	Count = 0,
	Connection = nil,
	Frames = 0,
	Elapsed = 0,
	FPS = nil,
	Ping = nil,
}

local function ReadPing()
	local Ok, Value = pcall(function()
		return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if Ok and typeof(Value) == "number" then
		return Value
	end

	local Ok2, Approx = pcall(function()
		return Players.LocalPlayer:GetNetworkPing() * 1000
	end)
	if Ok2 and typeof(Approx) == "number" then
		return Approx
	end

	return nil
end

-- Advances the sampler by one frame. Called from Heartbeat, exposed so it can be tested.
function Status.Step(DeltaTime)
	Sampler.Frames = Sampler.Frames + 1
	Sampler.Elapsed = Sampler.Elapsed + DeltaTime

	if Sampler.Elapsed < Status.SampleInterval then
		return
	end

	Sampler.FPS = Sampler.Frames / Sampler.Elapsed
	Sampler.Ping = ReadPing()
	Sampler.Frames = 0
	Sampler.Elapsed = 0

	for _, Listener in next, Sampler.Listeners do
		pcall(Listener, Sampler.FPS, Sampler.Ping)
	end
end

function Status.GetLast()
	return Sampler.FPS, Sampler.Ping
end

-- Returns a function that stops the subscription. The Heartbeat connection only exists while
-- at least one listener is subscribed.
function Status.Subscribe(Listener)
	local Token = {}
	Sampler.Listeners[Token] = Listener
	Sampler.Count = Sampler.Count + 1

	if not Sampler.Connection then
		Sampler.Frames = 0
		Sampler.Elapsed = 0
		Sampler.Connection = RunService.Heartbeat:Connect(Status.Step)
	end

	if Sampler.FPS then
		pcall(Listener, Sampler.FPS, Sampler.Ping)
	end

	return function()
		if Sampler.Listeners[Token] == nil then
			return
		end

		Sampler.Listeners[Token] = nil
		Sampler.Count = Sampler.Count - 1

		if Sampler.Count <= 0 and Sampler.Connection then
			Sampler.Connection:Disconnect()
			Sampler.Connection = nil
			Sampler.Count = 0
		end
	end
end

----------------------------------------------------------------------------------------------------
-- UI row
----------------------------------------------------------------------------------------------------

-- Options: Parent, TextSize (13), LayoutOrder, ShowFPS (true), ShowPing (true), Visible (true)
-- Returns { Frame, Update(fps, ping), SetVisible(bool), Destroy() }
function Status.NewRow(Options)
	Options = Options or {}
	local TextSize = Options.TextSize or 13
	local ShowFPS = Options.ShowFPS ~= false
	local ShowPing = Options.ShowPing ~= false

	local Row = New("Frame", {
		Name = "StatusRow",
		BackgroundTransparency = 1,
		AutomaticSize = "XY",
		Size = UDim2.new(0, 0, 0, 0),
		LayoutOrder = Options.LayoutOrder or 0,
		Visible = Options.Visible ~= false,
		Parent = Options.Parent,
	}, {
		New("UIListLayout", {
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 10),
		}),
	})

	local function MakeItem(Name, Order, Unit)
		local Dot = New("Frame", {
			Name = "Dot",
			Size = UDim2.new(0, 6, 0, 6),
			BackgroundColor3 = Status.Colors.Unknown,
			LayoutOrder = 1,
		}, {
			New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		})

		local Value = New("TextLabel", {
			Name = "Value",
			Text = "--",
			TextSize = TextSize,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
			TextXAlignment = "Left",
			LayoutOrder = 2,
			ThemeTag = { TextColor3 = "Text" },
		})

		local UnitLabel = New("TextLabel", {
			Name = "Unit",
			Text = Unit,
			TextSize = TextSize,
			TextTransparency = 0.55,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
			TextXAlignment = "Left",
			LayoutOrder = 3,
			ThemeTag = { TextColor3 = "Text" },
		})

		local Item = New("Frame", {
			Name = Name,
			BackgroundTransparency = 1,
			AutomaticSize = "XY",
			Size = UDim2.new(0, 0, 0, 0),
			LayoutOrder = Order,
			Parent = Row,
		}, {
			New("UIListLayout", {
				FillDirection = "Horizontal",
				VerticalAlignment = "Center",
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, 4),
			}),
			Dot,
			Value,
			UnitLabel,
		})

		return Item
	end

	local FPSItem = ShowFPS and MakeItem("FPS", 1, "fps") or nil
	local PingItem = ShowPing and MakeItem("Ping", 2, "ms") or nil

	local RowModule = { Frame = Row }

	local LastFPS, LastPing

	local function Apply(Item, Kind, Value)
		if not Item then
			return
		end

		local Rounded = typeof(Value) == "number" and Value == Value and math.floor(Value + 0.5) or nil
		Item.Value.Text = Rounded and tostring(Rounded) or "--"
		Item.Dot.BackgroundColor3 = Status.Colors[Status.Rate(Kind, Rounded)]
	end

	function RowModule:Update(FPS, Ping)
		if FPS ~= LastFPS then
			LastFPS = FPS
			Apply(FPSItem, "FPS", FPS)
		end
		if Ping ~= LastPing then
			LastPing = Ping
			Apply(PingItem, "Ping", Ping)
		end
	end

	function RowModule:SetVisible(Visible)
		Row.Visible = Visible and true or false
	end

	local Unsubscribe = Status.Subscribe(function(FPS, Ping)
		RowModule:Update(FPS, Ping)
	end)

	function RowModule:Destroy()
		Unsubscribe()
		Row:Destroy()
	end

	return RowModule
end

return Status
