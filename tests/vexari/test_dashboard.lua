-- Construction + behaviour tests for the dashboard components (Status, Chip, StatCard, ProfileCard,
-- PageHeader, the Stats/Profile/Header elements and the OpenButton status row) on a real Lua 5.4 VM
-- with a small fake Roblox Instance tree. This checks logic and that every constructor runs without errors.
-- It does NOT check how anything looks in Roblox.
local R = {}
local function check(name, cond, extra) R[#R + 1] = { name = name, ok = cond and true or false, extra = extra } end
local function eq(name, got, want) check(name, got == want, "got=" .. tostring(got) .. " want=" .. tostring(want)) end

---------------------------------------------------------------- fake Roblox
Env = { Heartbeat = nil, HeartbeatConnected = false, Ping = 78, Signals = {} }

function typeof(v) if type(v) == "table" and rawget(v, "__typeof") then return rawget(v, "__typeof") end return type(v) end
math.clamp = math.clamp or function(v, a, b) return math.max(a, math.min(b, v)) end
local function permissive(name) return setmetatable({}, { __index = function(t, k) local sub = setmetatable({}, { __index = function(_, n) return name .. "." .. k .. "." .. n end }); rawset(t, k, sub); return sub end }) end
Enum = permissive("Enum")
Font = { new = function(...) return { __typeof = "Font", ... } end }
UDim = { new = function(s, o) return { __typeof = "UDim", Scale = s, Offset = o } end }
UDim2 = { new = function(xs, xo, ys, yo) return { __typeof = "UDim2", xs = xs, xo = xo, ys = ys, yo = yo } end }
Vector2 = { new = function(x, y) return { __typeof = "Vector2", x = x, y = y } end }
Color3 = {
	fromHex = function(h) return { __typeof = "Color3", hex = h:gsub("^#", "") } end,
	new = function(r, g, b) return { __typeof = "Color3", r = r, g = g, b = b } end,
}
ColorSequence = { new = function(a, b) return { __typeof = "ColorSequence", a = a, b = b } end }

local Methods = {}
local function addChild(parent, child) local kids = rawget(parent, "Children"); kids[#kids + 1] = child end
local function removeChild(parent, child) local kids = rawget(parent, "Children"); for i, c in ipairs(kids) do if c == child then table.remove(kids, i) break end end end
local function signalOf(inst, name)
	local sigs = rawget(inst, "_signals")
	if not sigs[name] then
		sigs[name] = { handlers = {}, Connect = function(self, fn) self.handlers[#self.handlers + 1] = fn; return { Disconnect = function() end } end }
	end
	return sigs[name]
end
function Methods.Destroy(self)
	rawset(self, "Destroyed", true)
	local parent = rawget(self, "Parent")
	if parent then removeChild(parent, self); rawset(self, "Parent", nil) end
	for _, c in ipairs(rawget(self, "Children")) do rawset(c, "Destroyed", true) end
end
function Methods.IsA(self, c) return rawget(self, "ClassName") == c end
function Methods.GetPropertyChangedSignal(self, p) return signalOf(self, "Changed:" .. p) end
function Methods.FindFirstChild(self, n) for _, c in ipairs(rawget(self, "Children")) do if c.Name == n then return c end end end
function Methods.FindFirstChildWhichIsA(self, cls) for _, c in ipairs(rawget(self, "Children")) do if c.ClassName == cls then return c end end end
local SignalNames = { MouseEnter = true, MouseLeave = true, MouseButton1Click = true, InputBegan = true }

local function Instance_new(class)
	local inst = { ClassName = class, Name = class, __typeof = "Instance", Children = {}, _signals = {} }
	return setmetatable(inst, {
		__index = function(t, k)
			if Methods[k] then return Methods[k] end
			if SignalNames[k] then return signalOf(t, k) end
			for _, c in ipairs(rawget(t, "Children")) do if c.Name == k then return c end end
			return nil
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				local old = rawget(t, "Parent")
				if old then removeChild(old, t) end
				rawset(t, "Parent", v)
				if v then addChild(v, t) end
			else
				rawset(t, k, v)
			end
		end,
	})
end
local function fire(inst, name, ...) for _, h in ipairs(signalOf(inst, name).handlers) do h(...) end end

local Creator = { Font = "rbxassetid://12187365364", Objects = {} }
function Creator.New(class, props, children)
	local inst = Instance_new(class)
	for k, v in pairs(props or {}) do
		if k == "ThemeTag" then rawset(inst, "__theme", v); Creator.Objects[inst] = { Object = inst, Properties = v }
		elseif k ~= "Parent" then inst[k] = v end
	end
	-- like the real Creator.New: tolerate holes (a nil Icon in the middle of the list)
	local keys = {}; for k in pairs(children or {}) do keys[#keys + 1] = k end; table.sort(keys)
	for _, k in ipairs(keys) do children[k].Parent = inst end
	if props and props.Parent then inst.Parent = props.Parent end
	return inst
end
function Creator.AddThemeObject(obj, props) rawset(obj, "__theme", props); Creator.Objects[obj] = { Object = obj, Properties = props } end
function Creator.Tween(obj, dur, props) return { Play = function() for k, v in pairs(props) do obj[k] = v end end } end
function Creator.AddSignal(sig, fn) return sig:Connect(fn) end
function Creator.SafeCallback(fn, ...) return fn(...) end
function Creator.Image(icon, name, corner, folder, kind, themed, themedIcon, tag)
	local f = Creator.New("Frame", { Name = "IconFrame" }, { Creator.New("ImageLabel", { Name = "ImageLabel", Image = "icon:" .. tostring(icon) }) })
	rawset(f, "IconName", icon); return f
end
function Creator.Icon() return nil end
function Creator.Drag() return { Set = function() end } end
function Creator:ChangeTranslationKey() end

Env.Thumbs = {}
local Players = {
	LocalPlayer = { DisplayName = "らら", Name = "vbcghh_ll", UserId = 777, GetNetworkPing = function() return 0.05 end },
	GetUserThumbnailAsync = function(_, id) Env.Thumbs[#Env.Thumbs + 1] = id; return "rbxthumb://id=" .. id end,
}
local RunService = { Heartbeat = { Connect = function(_, fn) Env.Heartbeat = fn; Env.HeartbeatConnected = true; Env.Connects = (Env.Connects or 0) + 1
	return { Disconnect = function() Env.HeartbeatConnected = false end } end } }
local Stats = { Network = { ServerStatsItem = { ["Data Ping"] = { GetValue = function() if Env.Ping == "error" then error("no stat") end return Env.Ping end } } } }
game = { GetService = function(_, n) return ({ Players = Players, RunService = RunService, Stats = Stats, UserInputService = {} })[n] or {} end }
task = { spawn = function(f, ...) local co = coroutine.create(f); assert(coroutine.resume(co, ...)); return co end }

local Cache = {}
local Paths = {
	Format = "src/modules/Format.lua", Status = "src/components/ui/Status.lua", Chip = "src/components/ui/Chip.lua",
	StatCard = "src/components/ui/StatCard.lua", ProfileCard = "src/components/ui/ProfileCard.lua", PageHeader = "src/components/ui/PageHeader.lua",
	Stats = "src/elements/Stats.lua", Profile = "src/elements/Profile.lua", Header = "src/elements/Header.lua",
	Openbutton = "src/components/window/Openbutton.lua",
}
function require(path)
	local name = path:match("([^/]+)$")
	if name == "Creator" then return Creator end
	if Cache[name] then return Cache[name] end
	assert(Paths[name], "unmapped require " .. path)
	local f, e = loadfile(ROOT .. "/" .. Paths[name]); assert(f, e)
	Cache[name] = f(); return Cache[name]
end

local Format, Status = require("Format"), require("Status")
local function texts(inst, out) out = out or {}; if inst.Text and inst.Text ~= "" then out[#out + 1] = inst.Text end; for _, c in ipairs(inst.Children) do texts(c, out) end; return out end
local function find(inst, name) if inst.Name == name then return inst end for _, c in ipairs(inst.Children) do local r = find(c, name); if r then return r end end end

---------------------------------------------------------------- Format
eq("number: thousands", Format.Number(1540), "1,540")
eq("number: zero", Format.Number(0), "0")
eq("number: million", Format.Number(1234567), "1,234,567")
eq("number: fraction kept", Format.Number(1234567.5), "1,234,567.5")
eq("number: negative", Format.Number(-9876), "-9,876")
eq("number: .5", Format.Number(0.5), "0.5")
eq("number: 100.0", Format.Number(100.0), "100")
eq("number: under 1000", Format.Number(999), "999")
eq("number: text untouched", Format.Number("ON"), "ON")
eq("number: nil", Format.Number(nil), "nil")
eq("number: nan", Format.Number(0 / 0):lower():find("nan") ~= nil, true)
eq("color: palette name", Format.Color("Yellow").hex, "fbbf24")
eq("color: hex", Format.Color("#112233").hex, "112233")
eq("color: hex without #", Format.Color("112233").hex, "112233")
check("color: Color3 passthrough", Format.Color(Color3.new(1, 0, 0)).r == 1)
eq("color: invalid -> fallback", Format.Color("nope", "fb"), "fb")
eq("color: nil -> fallback", Format.Color(nil, "fb"), "fb")
eq("color: bad hex -> fallback", Format.Color("#12zz56", "fb"), "fb")

---------------------------------------------------------------- Status
eq("rate fps 60", Status.Rate("FPS", 60), "Good"); eq("rate fps 50", Status.Rate("FPS", 50), "Good")
eq("rate fps 49", Status.Rate("FPS", 49), "Ok"); eq("rate fps 30", Status.Rate("FPS", 30), "Ok"); eq("rate fps 29", Status.Rate("FPS", 29), "Bad")
eq("rate ping 78", Status.Rate("Ping", 78), "Good"); eq("rate ping 100", Status.Rate("Ping", 100), "Good")
eq("rate ping 130", Status.Rate("Ping", 130), "Ok"); eq("rate ping 200", Status.Rate("Ping", 200), "Ok"); eq("rate ping 201", Status.Rate("Ping", 201), "Bad")
eq("rate nil", Status.Rate("FPS", nil), "Unknown"); eq("rate unknown kind", Status.Rate("Nope", 1), "Unknown"); eq("rate nan", Status.Rate("FPS", 0 / 0), "Unknown")

do
	local got = {}
	local unsub1 = Status.Subscribe(function(f, p) got[#got + 1] = { f, p } end)
	check("subscribe connects Heartbeat once", Env.HeartbeatConnected and Env.Connects == 1)
	local unsub2 = Status.Subscribe(function() end)
	eq("second subscriber shares the connection", Env.Connects, 1)
	for _ = 1, 29 do Env.Heartbeat(1 / 60) end
	eq("no sample before 0.5s", #got, 0)
	Env.Heartbeat(1 / 60); Env.Heartbeat(1 / 60) -- 31 frames: float sums of 1/60 can stay a hair under 0.5 at exactly 30
	eq("one sample after 0.5s", #got, 1)
	check("fps is measured from frame times (~60)", math.abs(got[1][1] - 60) < 1, got[1][1])
	eq("ping read from Stats", got[1][2], 78)
	Env.Ping = "error"
	for _ = 1, 32 do Env.Heartbeat(1 / 60) end
	eq("ping falls back to GetNetworkPing*1000", got[2][2], 50)
	for _ = 1, 62 do Env.Heartbeat(1 / 120) end
	check("fps ~120 for 1/120 frames", math.abs(got[3][1] - 120) < 4, got[3][1])
	unsub1(); unsub1()
	check("still connected while one listener remains", Env.HeartbeatConnected)
	unsub2()
	check("disconnects when the last listener leaves", not Env.HeartbeatConnected)
	Env.Ping = 78
end

do
	local parent = Creator.New("Frame", {})
	local row = Status.NewRow({ Parent = parent, TextSize = 13 })
	eq("row has FPS and Ping items", #row.Frame.Children, 3) -- layout + 2 items
	local lastFPS, lastPing = Status.GetLast()
	check("a new row immediately shows the last measured values", find(row.Frame, "FPS").Value.Text == tostring(math.floor(lastFPS + 0.5))
		and find(row.Frame, "Ping").Value.Text == tostring(math.floor(lastPing + 0.5)), find(row.Frame, "FPS").Value.Text)
	row:Update(60, 78)
	eq("row fps text", find(row.Frame, "FPS").Value.Text, "60")
	eq("row ping text", find(row.Frame, "Ping").Value.Text, "78")
	eq("row fps dot green", find(row.Frame, "FPS").Dot.BackgroundColor3, Status.Colors.Good)
	row:Update(55.4, 130)
	eq("row rounds fps", find(row.Frame, "FPS").Value.Text, "55")
	eq("row ping 130 is amber", find(row.Frame, "Ping").Dot.BackgroundColor3, Status.Colors.Ok)
	row:Update(20, 400)
	check("row bad values are red", find(row.Frame, "FPS").Dot.BackgroundColor3 == Status.Colors.Bad and find(row.Frame, "Ping").Dot.BackgroundColor3 == Status.Colors.Bad)
	row:Update(nil, nil)
	check("nil shows -- and grey", find(row.Frame, "FPS").Value.Text == "--" and find(row.Frame, "FPS").Dot.BackgroundColor3 == Status.Colors.Unknown)
	row:SetVisible(false); eq("row can be hidden", row.Frame.Visible, false)
	check("row is subscribed", Env.HeartbeatConnected)
	row:Destroy()
	check("row destroy unsubscribes and removes the frame", (not Env.HeartbeatConnected) and row.Frame.Destroyed == true)
	local only = Status.NewRow({ Parent = parent, ShowPing = false })
	check("ShowPing=false builds fps only", find(only.Frame, "FPS") ~= nil and find(only.Frame, "Ping") == nil)
	only:Destroy()
end

---------------------------------------------------------------- Chip
do
	local Chip = require("Chip")
	local parent = Creator.New("Frame", {})
	local chip = Chip.New({ Text = "Waiting for a round", Icon = "hourglass", Parent = parent })
	check("chip neutral registers with the theme", Creator.Objects[chip.Frame] ~= nil)
	eq("chip text", find(chip.Frame, "Label").Text, "Waiting for a round")
	eq("chip icon created", find(chip.Frame, "IconFrame").IconName, "hourglass")
	chip:SetColor("Green")
	check("colored chip leaves the theme + uses the color", Creator.Objects[chip.Frame] == nil and chip.Frame.BackgroundColor3.hex == "34d399")
	chip:SetColor(nil)
	check("neutral again re-attaches to the theme", Creator.Objects[chip.Frame] ~= nil)
	chip:SetIcon("check"); eq("icon replaced", find(chip.Frame, "IconFrame").IconName, "check")
	local icons = 0; for _, c in ipairs(chip.Frame.Children) do if c.Name == "IconFrame" then icons = icons + 1 end end
	eq("only one icon after SetIcon", icons, 1)
	chip:SetIcon(nil); check("icon removed", find(chip.Frame, "IconFrame") == nil)
	chip:SetText("x"); eq("SetText", find(chip.Frame, "Label").Text, "x")
	chip:SetVisible(false); eq("SetVisible", chip.Frame.Visible, false)
end

---------------------------------------------------------------- StatCard
do
	local StatCard = require("StatCard")
	local parent = Creator.New("Frame", {})
	local card = StatCard.New({ Parent = parent, Items = {
		{ Key = "coins", Title = "Coins", Value = 1540, Color = "Yellow" },
		{ Key = "gems", Title = "Gems", Value = 0, Color = "Blue" },
		{ Title = "Level", Value = 100, Color = "Purple" },
	} })
	local cols = {}; for _, c in ipairs(card.Frame.Children) do if c.Name:match("^Column") then cols[#cols + 1] = c end end
	eq("3 columns", #cols, 3)
	eq("column width 1/3", cols[1].Size.xs, 1 / 3)
	eq("value formatted", cols[1].Value.Text, "1,540")
	eq("title upper-cased", cols[1].Title.Text, "COINS")
	eq("title accent color", cols[1].Title.TextColor3.hex, "fbbf24")
	check("last column has no divider", find(cols[3], "Divider") == nil and find(cols[1], "Divider") ~= nil)
	eq("key defaults to title", card:GetValue("Level"), 100)
	check("SetValue by key", card:SetValue("coins", 2500) and cols[1].Value.Text == "2,500")
	check("SetValue by index", card:SetValue(2, 12) and cols[2].Value.Text == "12")
	check("SetValue with value color", card:SetValue("gems", "ON", "Green") and cols[2].Value.TextColor3.hex == "34d399")
	check("SetValueColor(nil) returns to the theme", card:SetValueColor("gems", nil) and Creator.Objects[cols[2].Value] ~= nil)
	check("SetTitle", card:SetTitle("coins", "Gold") and cols[1].Title.Text == "GOLD")
	check("SetColor", card:SetColor("coins", "Red") and cols[1].Title.TextColor3.hex == "f87171")
	check("SetColor(nil) dims and follows the theme", card:SetColor("coins", nil) and cols[1].Title.TextTransparency == 0.45)
	check("unknown key returns false", card:SetValue("nope", 1) == false and card:SetTitle("nope", "x") == false and card:SetColor("nope", "Red") == false and card:GetValue("nope") == nil)
	check("nil value shows dash", card:SetValue("coins", nil) and cols[1].Value.Text == "-")
	card:Destroy(); check("destroy", card.Frame.Destroyed == true)
	local empty = StatCard.New({ Parent = parent })
	check("empty card builds", empty.Frame ~= nil)
	local one = StatCard.New({ Parent = parent, Items = { { Title = "Auto farm", Value = "ON", ValueColor = "Green" } } })
	eq("single item uses full width", find(one.Frame, "Column1").Size.xs, 1)
end

---------------------------------------------------------------- ProfileCard
do
	local ProfileCard = require("ProfileCard")
	local parent = Creator.New("Frame", {})
	local clicks = 0
	local card = ProfileCard.New({ Parent = parent, Button = { Title = "Lobby", Callback = function() clicks = clicks + 1 end },
		Status = { Text = "Waiting for a round", Icon = "hourglass" } })
	eq("default display name from LocalPlayer", find(card.Frame, "DisplayName").Text, "らら")
	eq("default username", find(card.Frame, "Username").Text, "@vbcghh_ll")
	eq("avatar loaded from the headshot of the local player", find(card.Frame, "Avatar").Image, "rbxthumb://id=777")
	local btn = find(card.Frame, "Button")
	eq("button text upper-cased", btn.Text, "LOBBY")
	fire(btn, "MouseButton1Click"); eq("button callback", clicks, 1)
	fire(btn, "MouseEnter"); eq("hover tween", btn.BackgroundTransparency, 0.7)
	fire(btn, "MouseLeave"); eq("leave tween", btn.BackgroundTransparency, 0.82)
	eq("status chip shown", find(card.Frame, "StatusRow").Visible, true)
	eq("status chip text", find(card.Frame, "Label").Text, "Waiting for a round")
	eq("names make room for the button", find(card.Frame, "Names").Size.xo, -(52 + 28 + 120))
	card:SetStatus("Playing", "play", "Green"); eq("SetStatus text", find(card.Frame, "Label").Text, "Playing")
	local chips = 0; for _, c in ipairs(find(card.Frame, "StatusRow").Children) do if c.Name == "Chip" then chips = chips + 1 end end
	eq("SetStatus reuses the one chip", chips, 1)
	card:SetStatus(nil); check("SetStatus(nil) hides", find(card.Frame, "StatusRow").Visible == false)
	card:SetStatus({ Text = "Back", Icon = "check" }); check("SetStatus(table) shows again", find(card.Frame, "StatusRow").Visible == true and find(card.Frame, "Label").Text == "Back")
	card:SetButton(nil)
	check("SetButton(nil) removes it and gives the room back", find(card.Frame, "Button") == nil and find(card.Frame, "Names").Size.xo == -(52 + 28))
	card:SetButton({ Title = "Join", Callback = function() clicks = clicks + 10 end })
	fire(find(card.Frame, "Button"), "MouseButton1Click"); eq("new button callback replaces the old one", clicks, 11)
	card:SetName("Neo"); card:SetUsername("@neo")
	check("SetName/SetUsername", find(card.Frame, "DisplayName").Text == "Neo" and find(card.Frame, "Username").Text == "@neo")
	card:SetAvatar(42); eq("SetAvatar(userId)", find(card.Frame, "Avatar").Image, "rbxthumb://id=42")
	card:SetAvatar("rbxassetid://99"); eq("SetAvatar(image)", find(card.Frame, "Avatar").Image, "rbxassetid://99")
	local anon = ProfileCard.New({ Parent = parent, Anonymous = true })
	check("anonymous hides the real identity", find(anon.Frame, "DisplayName").Text == "Anonymous" and find(anon.Frame, "Username").Text == "@anonymous" and find(anon.Frame, "Avatar").Image == "rbxthumb://id=1")
	local named = ProfileCard.New({ Parent = parent, Title = "Custom", Desc = "@custom", Avatar = "rbxassetid://5" })
	check("custom title / desc / avatar", find(named.Frame, "DisplayName").Text == "Custom" and find(named.Frame, "Username").Text == "@custom" and find(named.Frame, "Avatar").Image == "rbxassetid://5")
	check("no button when not requested", find(named.Frame, "Button") == nil)
	card:Destroy(); check("destroy", card.Frame.Destroyed == true)
end

---------------------------------------------------------------- PageHeader
do
	local PageHeader = require("PageHeader")
	local parent = Creator.New("Frame", {})
	local h = PageHeader.New({ Parent = parent, Title = "Home", Eyebrow = "Overview", Icon = "home" })
	eq("eyebrow upper-cased", find(h.Frame, "Eyebrow").Text, "OVERVIEW")
	eq("title", find(h.Frame, "Title").Text, "Home")
	eq("icon", find(h.Frame, "IconFrame").IconName, "home")
	h:SetEyebrow(""); eq("empty eyebrow hides the line", find(h.Frame, "Eyebrow").Visible, false)
	h:SetEyebrow("Settings"); check("eyebrow back", find(h.Frame, "Eyebrow").Visible == true and find(h.Frame, "Eyebrow").Text == "SETTINGS")
	h:SetTitle("Player"); eq("SetTitle", find(h.Frame, "Title").Text, "Player")
	h:SetIcon("user"); eq("SetIcon", find(h.Frame, "IconFrame").IconName, "user")
	local plain = PageHeader.New({ Parent = parent, Title = "No eyebrow" })
	eq("no eyebrow -> line hidden", find(plain.Frame, "Eyebrow").Visible, false)
end

---------------------------------------------------------------- elements
do
	local cfgWindow = { ElementConfig = { UICorner = 13 }, Folder = "myhub" }
	local parent = Creator.New("Frame", {})
	local t, stats = require("Stats"):New({ Parent = parent, Window = cfgWindow, Items = { { Key = "a", Title = "A", Value = 1 } } })
	check("Stats element type + frame", t == "Stats" and stats.ElementFrame.Name == "StatCard" and stats.__type == "Stats")
	check("Stats element methods", stats:SetValue("a", 5000) and stats:GetValue("a") == 5000 and stats:SetTitle("a", "B") and stats:SetColor("a", "Red") and stats:SetValueColor("a", "Green"))
	stats:Destroy(); check("Stats destroy", stats.ElementFrame.Destroyed == true)
	local t2, prof = require("Profile"):New({ Parent = parent, Window = cfgWindow, Title = "Neo", Button = { Title = "Go" } })
	check("Profile element type + frame", t2 == "Profile" and prof.ElementFrame.Name == "ProfileCard")
	check("Profile element methods", (prof:SetName("X") == nil) and find(prof.ElementFrame, "DisplayName").Text == "X")
	prof:SetStatus("hi", "check"); prof:SetButton(nil); prof:SetAvatar(5); prof:SetUsername("@u"); prof:Destroy()
	local t3, head = require("Header"):New({ Parent = parent, Window = cfgWindow, Title = "Home", Eyebrow = "Overview", Icon = "home" })
	check("Header element type + frame", t3 == "Header" and head.ElementFrame.Name == "PageHeader")
	head:SetTitle("T"); head:SetEyebrow("E"); head:SetIcon("x"); head:Destroy()
	-- the element loader treats table values whose key ends in "Frame" as element frames: ours must not have any
	for _, m in ipairs({ stats, prof, head }) do
		local bad
		for k, v in pairs(m) do if type(v) == "table" and tostring(k):match("Frame$") and k ~= "ElementFrame" then bad = k end end
		check("element has no table field ending in 'Frame' (" .. m.__type .. ")", bad == nil, bad)
	end
end

---------------------------------------------------------------- OpenButton (modified)
do
	local OpenButton = require("Openbutton")
	local parentGui = Creator.New("Frame", {})
	local Window = { Title = "Star Hub", Icon = nil, Parent = parentGui, UIPadding = 14, Folder = "x", IconThemed = false }
	local ob = OpenButton.New(Window)
	local stack = find(ob.Button, "TextStack")
	check("title now lives in a text stack", stack ~= nil and find(stack, "Title") == nil and #stack.Children == 2, #stack.Children)
	eq("pill is 44 high without status", ob.Button.Size.yo, 44)
	ob:SetStatus(true)
	check("status row added under the title", find(stack, "StatusRow") ~= nil)
	eq("pill grows to 56 with status", ob.Button.Size.yo, 56)
	eq("inner button follows", ob.Button.TextButton.Size.yo, 48)
	check("Heartbeat running for the pill", Env.HeartbeatConnected)
	ob:SetStatus({ Ping = false })
	check("status can be fps only", find(stack, "FPS") ~= nil and find(stack, "Ping") == nil)
	local rows = 0; for _, c in ipairs(stack.Children) do if c.Name == "StatusRow" then rows = rows + 1 end end
	eq("replacing the status keeps a single row", rows, 1)
	ob:SetStatus(nil)
	check("status removed: back to 44 and Heartbeat released", ob.Button.Size.yo == 44 and not Env.HeartbeatConnected and find(stack, "StatusRow") == nil)
	ob:Edit({ Style = "Minimal", Title = "Star Hub", OnlyMobile = false })
	check("Minimal style: dark fill + thin grey stroke", ob.Button.BackgroundColor3.hex == "0c0c0f" and ob.Button.UIStroke.Thickness == 1.5
		and ob.Button.UIStroke.UIGradient.Color.a.hex == "a1a1aa")
	ob:Edit({ OnlyIcon = true })
	eq("OnlyIcon hides the whole text stack", stack.Visible, false)
	ob:Edit({ OnlyIcon = false })
	eq("OnlyIcon=false shows it again", stack.Visible, true)
	ob:SetIcon("star"); eq("icon size follows the style (30)", find(ob.Button, "IconFrame").Size.xo, 30)
	local old = OpenButton.New({ Title = "Old", Parent = parentGui, UIPadding = 14, Folder = "x" })
	old:Edit({ Title = "Renamed" })
	eq("default style untouched", old.Button.UIStroke.Thickness, 2)
end

local out, failed = {}, 0
for _, r in ipairs(R) do if not r.ok then failed = failed + 1; out[#out + 1] = "FAIL  " .. r.name .. "   [" .. tostring(r.extra) .. "]" end end
out[#out + 1] = string.format("%d checks, %d passed, %d failed", #R, #R - failed, failed)
return table.concat(out, "\n")
