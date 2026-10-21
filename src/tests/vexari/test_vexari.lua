-- Behaviour tests for Vexari UI's new modules, run on a real Lua 5.4 VM with a mocked Roblox API.
-- These test the LOGIC (parsing, state machine, wiring). They do NOT test Roblox rendering.
local R = {}
local function check(name, cond, extra)
	R[#R + 1] = { name = name, ok = cond and true or false, extra = extra }
end
local function eq(name, got, want)
	check(name, got == want, "got=" .. tostring(got) .. " want=" .. tostring(want))
end

---------------------------------------------------------------- Roblox mocks
local now = 0
os.clock = function() return now end
Env = { Status = {}, Loadable = {}, OnWait = nil, Objects = {}, Http = {}, Files = {}, Hits = 0, Preloads = {}, Created = 0 }

task = {}
task.wait = function(t)
	now = now + (t or 0.03)
	if Env.OnWait then local f = Env.OnWait; Env.OnWait = nil; f() end
	return t
end
task.spawn = function(f, ...)
	local co = coroutine.create(f)
	local ok, err = coroutine.resume(co, ...)
	if not ok then error(err, 0) end
	return co
end
task.defer = task.spawn

function typeof(v) return type(v) end
math.clamp = function(v, a, b) return math.max(a, math.min(b, v)) end
table.clear = function(t) for k in pairs(t) do t[k] = nil end end

local function enum_group(name, members)
	return setmetatable(members or {}, { __index = function(_, k) error(k .. " is not a valid member of Enum." .. name, 0) end })
end
Enum = {
	ScaleType = { Crop = "Crop", Fit = "Fit", Stretch = "Stretch" },
	AssetFetchStatus = { Success = "Success", Failure = "Failure", TimedOut = "TimedOut" },
	Font = enum_group("Font", { Gotham = "Gotham", SourceSans = "SourceSans", Arial = "Arial" }),
	EasingStyle = { Quint = "Quint" },
	EasingDirection = { Out = "Out" },
}
Font = { fromEnum = function(e) return { Family = "rbxasset://fonts/families/" .. tostring(e) .. ".json" } end }
UDim = { new = function(a, b) return { Scale = a, Offset = b } end }
UDim2 = { new = function(a, b, c, d) return { a, b, c, d } end }

local function NewInstance(class, props, children)
	local data = { ClassName = class, Image = "", IsLoaded = false, Visible = true, ImageTransparency = 0 }
	local o = {}
	setmetatable(o, {
		__index = function(_, k)
			if k == "IsA" then return function(_, c) return c == class end end
			if k == "Destroy" then return function() data.Parent = nil; data.Destroyed = true end end
			if k == "Pause" then return function() data.Paused = true end end
			if k == "Play" then return function() data.Paused = false end end
			if k == "FindFirstChildWhichIsA" then return function(_, c) return data.Found and data.Found[c] end end
			return data[k]
		end,
		__newindex = function(_, k, v)
			data[k] = v
			if k == "Image" and class == "ImageLabel" then data.IsLoaded = Env.Loadable[v] == true end
		end,
	})
	for k, v in pairs(props or {}) do o[k] = v end
	if class == "ImageLabel" then Env.Created = Env.Created + 1 end
	return o
end

local Creator = {
	New = NewInstance,
	Tween = function(obj, _, props) return { Play = function() for k, v in pairs(props) do obj[k] = v end end } end,
	Request = nil,
}

local ContentProvider = { PreloadAsync = function(_, list, cb)
	local content = list[1]
	Env.Preloads[#Env.Preloads + 1] = content
	local st = Env.Status[content]
	if st == "Hang" then coroutine.yield() end
	if cb then cb(content, Enum.AssetFetchStatus[st or "Success"]) end
end }
game = {
	GetService = function(_, n) return n == "ContentProvider" and ContentProvider or {} end,
	GetObjects = function(_, id) return Env.Objects[id] end,
	HttpGet = function(_, url) Env.Hits = Env.Hits + 1; local b = Env.Http[url]; if not b then error("HTTP 404", 0) end; return b end,
}

local function load(path) local f, e = loadfile(ROOT .. "/" .. path); assert(f, e); return f() end

---------------------------------------------------------------- Background.Parse
local Background = load("src/components/window/Background.lua")
local function parse(i) local r, e = Background.Parse(i); return r, e end
local function P(name, input, kind, content)
	local r, e = parse(input)
	check("parse: " .. name, r and r.Kind == kind and r.Content == content, r and (r.Kind .. " " .. r.Content) or e)
end
local function PE(name, input)
	local r, e = parse(input)
	check("parse rejects: " .. name, r == nil and type(e) == "string" and #e > 0, r and r.Content or e)
end
P("number", 123456, "roblox", "rbxassetid://123456")
P("digits with spaces", "  123456  ", "roblox", "rbxassetid://123456")
P("rbxassetid", "rbxassetid://123", "roblox", "rbxassetid://123")
P("rbxassetid uppercase", "RBXASSETID://123", "roblox", "rbxassetid://123")
P("quoted", "'123'", "roblox", "rbxassetid://123")
P("leading zeros", "000123", "roblox", "rbxassetid://123")
P("asset link", "http://www.roblox.com/asset/?id=987654", "roblox", "rbxassetid://987654")
P("assetdelivery link", "https://assetdelivery.roblox.com/v1/asset/?id=321", "roblox", "rbxassetid://321")
P("library link", "https://www.roblox.com/library/555/Name", "roblox", "rbxassetid://555")
P("create store link", "https://create.roblox.com/store/asset/777/Cool", "roblox", "rbxassetid://777")
P("catalog link", "https://www.roblox.com/catalog/42/x", "roblox", "rbxassetid://42")
P("thumb", "rbxthumb://type=Asset&id=123&w=420&h=420", "roblox", "rbxthumb://type=Asset&id=123&w=420&h=420")
P("builtin", "rbxasset://textures/foo.png", "builtin", "rbxasset://textures/foo.png")
P("external url", "https://example.com/pic.png", "http", "https://example.com/pic.png")
P("spoof host notroblox.com is external", "https://notroblox.com/asset/?id=5", "http", "https://notroblox.com/asset/?id=5")
P("spoof roblox.com.evil.com is external", "https://roblox.com.evil.com/asset/?id=5", "http", "https://roblox.com.evil.com/asset/?id=5")
PE("empty", ""); PE("spaces only", "   "); PE("nil", nil); PE("table", {}); PE("boolean", true)
PE("zero", "0"); PE("zeros", "000"); PE("negative number", -5); PE("fraction", 1.5); PE("nan", 0 / 0)
PE("too big number", 9007199254740993 * 4); PE("20 digits", "12345678901234567890")
PE("words", "abc"); PE("inner space", "has space"); PE("long", string.rep("1", 3000))
PE("video", "video:abc"); PE("bad thumb", "rbxthumb://bad")
PE("roblox link without id", "https://www.roblox.com/home"); PE("host without dot", "https://localhost/x")

---------------------------------------------------------------- Manager
local function Setup(opts)
	opts = opts or {}
	Env.Created = 0
	local host = NewInstance("Frame", { Parent = {} })
	local original = NewInstance(opts.video and "VideoFrame" or "ImageLabel", { Parent = host, ImageTransparency = 0 })
	local gradient = NewInstance("ImageLabel", { Parent = host })
	local Window = { Destroyed = false, Closed = false, BackgroundImageTransparency = 0, UICorner = 16, Folder = "Test",
		UIElements = { BackgroundGradient = opts.gradient and gradient or nil } }
	local Manager
	function Window:SetBackgroundImageTransparency(v) self.BackgroundImageTransparency = v; Manager:ApplyTransparency() end
	Manager = Background.New(Window, Creator, { Host = host, Original = original, OriginalTransparency = 0 })
	Env.Base = Env.Created -- ImageLabels made by the fixture itself (original + gradient)
	return Manager, Window, host, original, gradient
end

-- 1. success
do
	Env.Loadable["rbxassetid://111"] = true
	local M, W, host, orig, grad = Setup({ gradient = true })
	local ok, err = M:Apply("111", { Transparency = 0.35, ScaleType = "Fit" })
	check("apply ok", ok == true, err)
	check("Active", M.Active == true)
	eq("exactly one custom ImageLabel created", Env.Created - Env.Base, 1)
	check("label image set", M.Label and M.Label.Image == "rbxassetid://111")
	eq("label ZIndex 0", M.Label.ZIndex, 0)
	eq("label scale type", M.Label.ScaleType, "Fit")
	eq("label transparency shown", M.Label.ImageTransparency, 0.35)
	eq("window transparency stored", W.BackgroundImageTransparency, 0.35)
	eq("original hidden", orig.Visible, false)
	eq("gradient hidden", grad.Visible, false)
	eq("label visible", M.Label.Visible, true)
	local first = M.Label

	-- 2. re-apply reuses the same ImageLabel
	Env.Loadable["rbxassetid://222"] = true
	local created = Env.Created
	local ok2 = M:Apply(222)
	check("re-apply ok", ok2 == true)
	check("same ImageLabel instance reused", M.Label == first and Env.Created == created, "created " .. created .. "->" .. Env.Created)
	eq("new image assigned", M.Label.Image, "rbxassetid://222")

	-- 3. transparency API reaches the custom label
	W:SetBackgroundImageTransparency(0.6)
	eq("transparency applied to custom label", M.Label.ImageTransparency, 0.6)

	-- 4. closed window keeps image invisible, OnOpen restores
	W.Closed = true
	W:SetBackgroundImageTransparency(0.5)
	eq("closed: label untouched by slider", M.Label.ImageTransparency, 0.6)
	W.Closed = false
	M:OnOpen()
	eq("OnOpen tweens to window value", M.Label.ImageTransparency, 0.5)
	M:OnClose()
	eq("OnClose hides label", M.Label.ImageTransparency, 1)

	-- 5. failed apply keeps previous image
	Env.Status["rbxassetid://333"] = "Failure"
	local ok3, err3 = M:Apply("333")
	check("failed fetch returns false+msg", ok3 == false and type(err3) == "string" and err3:find("could not load"), err3)
	eq("previous image kept after failure", M.Label.Image, "rbxassetid://222")
	check("still Active after failure", M.Active == true)

	-- 6. reset
	M:Reset()
	check("reset destroys label", first.Destroyed == true and M.Label == nil)
	check("reset: Active false", M.Active == false)
	eq("reset: original visible again", orig.Visible, true)
	eq("reset: gradient visible again", grad.Visible, true)
	eq("reset: transparency restored", W.BackgroundImageTransparency, 0)
end

-- first-apply failures leave no label behind
do
	local M = Setup()
	local created = Env.Created
	Env.Status["rbxassetid://404"] = "Failure"
	local ok, err = M:Apply("404")
	check("first apply failure: false", ok == false, err)
	check("first apply failure: no ImageLabel left", M.Label == nil and Env.Created == created)
	local ok2, err2 = M:Apply("not valid")
	check("invalid input: false+msg, no label", ok2 == false and type(err2) == "string" and M.Label == nil, err2)
end

-- decal id (loads as asset but is not an image) -> resolved through GetObjects
do
	local M = Setup()
	Env.Loadable["rbxassetid://555"] = false
	Env.Loadable["rbxassetid://999"] = true
	Env.Objects["rbxassetid://555"] = { NewInstance("Decal", { Texture = "rbxassetid://999" }) }
	Env.Objects["rbxassetid://555"][1].Found = nil
	-- make IsA("Decal") true for root
	local ok, err = M:Apply("555")
	check("decal id resolved to image id", ok == true and M.Label and M.Label.Image == "rbxassetid://999", err)
	eq("content stored", M.Content, "rbxassetid://999")
end
-- decal that cannot be resolved -> clear error, nothing left behind
do
	local M = Setup()
	Env.Loadable["rbxassetid://556"] = false
	Env.Objects["rbxassetid://556"] = nil
	local before = Env.Created
	local ok, err = M:Apply("556")
	check("unresolvable decal -> not displayable msg", ok == false and err:find("not a displayable image"), err)
	check("unresolvable decal -> no label left", M.Label == nil)
end

-- an active image must survive a later Apply of an asset that loads but cannot be displayed
do
	local M = Setup()
	Env.Loadable["rbxassetid://20"] = true
	M:Apply("20")
	Env.Loadable["rbxassetid://21"] = false
	Env.Objects["rbxassetid://21"] = nil
	local ok, err = M:Apply("21")
	check("undisplayable asset while active -> false+msg", ok == false and err:find("not a displayable image"), err)
	check("undisplayable asset: previous image restored, still Active", M.Label and M.Label.Image == "rbxassetid://20" and M.Active == true,
		M.Label and M.Label.Image)
end

-- preload hangs forever -> times out (fake clock), does not freeze
do
	local M = Setup()
	Env.Status["rbxassetid://600"] = "Hang"
	local t0 = now
	local ok, err = M:Apply("600")
	check("preload hang -> timeout error", ok == false and err:find("Timed out"), err)
	check("timeout bounded by PreloadTimeout", now - t0 <= Background.PreloadTimeout + 1, "waited " .. (now - t0))
end

-- two requests racing: the older one is cancelled promptly, the newer wins
do
	local M = Setup()
	Env.Status["rbxassetid://700"] = "Hang"
	Env.Loadable["rbxassetid://701"] = true
	local resB
	Env.OnWait = function() resB = { M:Apply("701") } end -- B starts while A is waiting
	local t0 = now
	local okA, errA = M:Apply("700")
	check("older request cancelled", okA == false and errA:sub(1, 9) == "Cancelled", errA)
	check("older request stopped waiting quickly", now - t0 < 1, "waited " .. (now - t0))
	check("newer request succeeded", resB and resB[1] == true and M.Label and M.Label.Image == "rbxassetid://701")
	eq("only one custom ImageLabel exists after racing requests", Env.Created - Env.Base, 1)
end

-- Reset while a load is in flight cancels it
do
	local M = Setup()
	Env.Status["rbxassetid://710"] = "Hang"
	local res
	Env.OnWait = function() M:Reset() end
	local ok, err = M:Apply("710")
	check("reset cancels pending apply", ok == false and err:sub(1, 9) == "Cancelled", err)
	check("reset left no label", M.Label == nil and M.Active == false)
end

-- destroyed window
do
	local M, W = Setup()
	W.Destroyed = true
	local ok, err = M:Apply("1")
	check("destroyed window -> false+msg", ok == false and err:find("no longer exists"), err)
end

-- video original is paused when custom image active and resumed on reset
do
	Env.Loadable["rbxassetid://800"] = true
	local M, W, host, video = Setup({ video = true })
	M:Apply("800")
	check("video hidden+paused", video.Visible == false and video.Paused == true)
	M:Reset()
	check("video visible+playing again", video.Visible == true and video.Paused == false)
end

-- scale type API
do
	local M = Setup()
	local ok1 = M:SetScaleType("Stretch"); local ok2, e2 = M:SetScaleType("Banana")
	check("scale type accepted/rejected", ok1 == true and ok2 == false and type(e2) == "string")
	Env.Loadable["rbxassetid://810"] = true
	M:Apply("810")
	eq("scale type used for new label", M.Label.ScaleType, "Stretch")
	M:Reset()
	eq("scale type kept after reset", M.ScaleType, "Stretch")
end

-- external URLs: no executor functions
do
	local M = Setup()
	local ok, err = M:Apply("https://example.com/a.png")
	check("url without executor fs -> clear message", ok == false and err:find("executor"), err)
end
-- external URLs with a fake executor
do
	local PNG = "\137PNG\r\n\26\n" .. string.rep("x", 40)
	Env.Http["https://example.com/a.png"] = PNG
	Env.Http["https://example.com/page.html"] = "<html>" .. string.rep("x", 40)
	Env.Http["https://example.com/anim.gif"] = "GIF89a" .. string.rep("x", 40)
	Env.Http["https://example.com/big.png"] = "\137PNG\r\n\26\n" .. string.rep("x", Background.MaxDownloadBytes + 1)
	local folders = {}
	writefile = function(p, c) Env.Files[p] = c end
	isfile = function(p) return Env.Files[p] ~= nil end
	isfolder = function(p) return folders[p] == true end
	makefolder = function(p) folders[p] = true end
	getcustomasset = function(p) local a = "rbxasset://custom/" .. p; Env.Loadable[a] = true; return a end

	local M = Setup()
	local ok, err = M:Apply("https://example.com/a.png")
	check("url download ok", ok == true and M.Label.Image:find("^rbxasset://custom/Test/assets/.vexari_bg_") ~= nil, err or M.Label.Image)
	check("url download wrote a .png", next(Env.Files) ~= nil and (next(Env.Files)):sub(-4) == ".png")
	local hits = Env.Hits
	M:Reset(); M:Apply("https://example.com/a.png")
	eq("second apply of same URL uses the cache (no new HTTP hit)", Env.Hits, hits)
	local ok2, err2 = M:Apply("https://example.com/page.html")
	check("non-image download rejected", ok2 == false and err2:find("did not return"), err2)
	local ok3, err3 = M:Apply("https://example.com/anim.gif")
	check("gif rejected with reason", ok3 == false and err3:find("GIF"), err3)
	local ok4, err4 = M:Apply("https://example.com/missing.png")
	check("http failure reported", ok4 == false and type(err4) == "string", err4)
	local ok5, err5 = M:Apply("https://example.com/big.png")
	check("oversized download rejected", ok5 == false and err5:find("10 MB"), err5)
	check("rejected downloads did not replace the active image", M.Label and M.Label.Image:find("^rbxasset://custom/") ~= nil)
	writefile, isfile, isfolder, makefolder, getcustomasset = nil, nil, nil, nil, nil
end

---------------------------------------------------------------- Fonts
do
	local Fonts = load("src/modules/Fonts.lua")
	Fonts.Init("rbxassetid://12187365364")
	local names = Fonts.GetNames()
	eq("fonts: default first", names[1], "Default")
	eq("fonts: only existing enum fonts registered (Gotham, Source Sans, Arial)", table.concat(names, ","), "Default,Gotham,Source Sans,Arial")
	local fam, nm = Fonts.Resolve("Gotham")
	check("fonts: resolve by name", fam == "rbxasset://fonts/families/Gotham.json" and nm == "Gotham", fam)
	local fam2, nm2 = Fonts.Resolve("rbxasset://fonts/families/Gotham.json")
	check("fonts: resolve by family returns name", nm2 == "Gotham")
	local fam3, nm3 = Fonts.Resolve("rbxassetid://5555")
	check("fonts: raw id passes through", fam3 == "rbxassetid://5555" and nm3 == nil)
	check("fonts: empty/nil rejected", Fonts.Resolve("") == nil and Fonts.Resolve(nil) == nil and Fonts.Resolve(5) == nil)
	check("fonts: Add rejects bad args", Fonts.Add("", "x") == false and Fonts.Add("x", "") == false and Fonts.Add(nil, "x") == false)
	check("fonts: Add new", Fonts.Add("Mine", "rbxassetid://1") == true and Fonts.Resolve("Mine") == "rbxassetid://1")
	local n = #Fonts.GetNames()
	Fonts.Add("Mine", "rbxassetid://2")
	check("fonts: Add same name updates, no duplicate", #Fonts.GetNames() == n and Fonts.Resolve("Mine") == "rbxassetid://2")
	Fonts.Init("rbxassetid://9")
	eq("fonts: Init resets list", #Fonts.GetNames(), 4)
end

---------------------------------------------------------------- Settings tab wiring
do
	local Settings = load("src/components/window/Settings.lua")
	local function Make(cfg, opts)
		opts = opts or {}
		local tab = { els = {} }
		local textbox = { Text = "" }
		for _, kind in ipairs({ "Section", "Dropdown", "Slider", "Input", "Button", "Paragraph" }) do
			tab[kind] = function(_, c)
				local el = { Kind = kind, Config = c, Title = c.Title }
				function el:Set(v) el.Value = v; if kind == "Input" then textbox.Text = v end; if c.Callback then c.Callback(v) end end
				function el:SetTitle(t) el.Title = t end
				el.ElementFrame = { FindFirstChildWhichIsA = function() if opts.noTextbox then return nil end return textbox end }
				tab.els[#tab.els + 1] = el
				-- the real Dropdown / Input fire their callback during construction
				if (kind == "Dropdown" or kind == "Input") and c.Callback then c.Callback(c.Value) end
				return el
			end
		end
		local calls, notes = {}, {}
		local active = false
		local Window = { Transparent = false, Destroyed = false }
		function Window:Tab(c) calls.tab = c; return tab end
		function Window:SetBackground(src, o) calls.set = { src, o }; local r = opts.result or { true }; return r[1], r[2] end
		function Window:ResetBackground() calls.reset = (calls.reset or 0) + 1 end
		function Window:GetBackground() return { Active = active } end
		function Window:SetBackgroundImageTransparency(v) calls.imgTr = v end
		function Window:SetBackgroundScaleType(n) calls.scale = n end
		function Window:SetBackgroundTransparency(v) calls.winTr = v end
		local themes = { Dark = {}, Light = {}, Vexari = {} }
		local WindUI = { Version = "1.7.0", TransparencyValue = 0.15, Themes = themes, Creator = { Theme = themes.Dark } }
		function WindUI:GetThemes() return themes end
		function WindUI:SetTheme(n) calls.theme = n; WindUI.Creator.Theme = themes[n]; return themes[n] end
		function WindUI:GetFonts() return { "Default", "Gotham" } end
		local curFont = "Default"
		function WindUI:GetCurrentFont() return curFont end
		function WindUI:SetFont(n) calls.font = n; curFont = n; return true end
		function WindUI:Notify(c) notes[#notes + 1] = c end
		local t = Settings(Window, WindUI, cfg)
		return t, tab, Window, WindUI, calls, notes, textbox, function(v) active = v end
	end
	local function find(tab, kind, title) for _, e in ipairs(tab.els) do if e.Kind == kind and e.Title == title then return e end end end

	local t, tab, W, U, calls, notes, tb = Make()
	check("settings: creates Settings tab", calls.tab and calls.tab.Title == "Settings" and calls.tab.Icon == "settings")
	check("settings: no side effects while elements initialise", calls.theme == nil and calls.font == nil and calls.set == nil and #notes == 0,
		tostring(calls.theme) .. "/" .. tostring(calls.font) .. "/" .. #notes)
	check("settings: second call returns the same tab, no duplicates", Settings(W, U, {}) == t and #tab.els == #tab.els)
	local n = #tab.els; Settings(W, U, {}); eq("settings: no new elements on 2nd call", #tab.els, n)

	local theme = find(tab, "Dropdown", "Theme")
	check("settings: theme list sorted + current selected", theme and table.concat(theme.Config.Values, ",") == "Dark,Light,Vexari" and theme.Config.Value == "Dark")
	theme.Config.Callback("Vexari")
	check("settings: theme change applied + notified", calls.theme == "Vexari" and #notes == 1 and notes[1].Title == "Theme applied")
	calls.theme = nil; theme.Config.Callback("Vexari")
	check("settings: same theme ignored", calls.theme == nil and #notes == 1)

	local font = find(tab, "Dropdown", "Font")
	font.Config.Callback("Gotham")
	check("settings: font change applied", calls.font == "Gotham" and #notes == 2)
	calls.font = nil; font.Config.Callback("Gotham")
	check("settings: same font ignored", calls.font == nil)

	local winTr = find(tab, "Slider", "Window transparency")
	winTr.Config.Callback(0.3)
	eq("settings: window transparency slider", calls.winTr, 0.3)

	local imgTr = find(tab, "Slider", "Image transparency")
	imgTr.Config.Callback(0.4)
	check("settings: image slider does not touch window while no custom image", calls.imgTr == nil)

	-- Apply
	local apply = find(tab, "Button", "Apply background")
	tb.Text = "  123456  "
	apply.Config.Callback()
	check("settings: Apply sends text + transparency + scale", calls.set and calls.set[1] == "  123456  " and calls.set[2].Transparency == 0.4 and calls.set[2].ScaleType == "Crop",
		calls.set and (tostring(calls.set[1]) .. "/" .. tostring(calls.set[2].Transparency)))
	check("settings: success notification + title restored", notes[#notes].Title == "Background applied" and apply.Title == "Apply background")

	local scale = find(tab, "Dropdown", "Image scaling")
	scale.Config.Callback("Fit")
	eq("settings: scale Fit -> Fit", calls.scale, "Fit")
	scale.Config.Callback("Fill")
	eq("settings: scale Fill -> Crop", calls.scale, "Crop")
	scale.Config.Callback("Stretch"); apply.Config.Callback()
	eq("settings: scale choice sent with Apply", calls.set[2].ScaleType, "Stretch")

	-- reset
	local reset = find(tab, "Button", "Reset background")
	local input = find(tab, "Input", "Image")
	reset.Config.Callback()
	check("settings: Reset calls ResetBackground and clears input", calls.reset == 1 and input.Value == "" and tb.Text == "" and notes[#notes].Title == "Background reset")

	-- failure + cancelled
	local t2, tab2, W2, U2, calls2, notes2, tb2 = Make(nil, { result = { false, "Roblox could not load that asset" } })
	local apply2 = find(tab2, "Button", "Apply background")
	tb2.Text = "42"; apply2.Config.Callback()
	check("settings: failure shown to user", notes2[#notes2].Title == "Background not applied" and notes2[#notes2].Content == "Roblox could not load that asset")
	local t3, tab3, W3, U3, calls3, notes3, tb3 = Make(nil, { result = { false, "Cancelled: a newer background request replaced this one." } })
	find(tab3, "Button", "Apply background").Config.Callback()
	eq("settings: cancelled request stays silent", #notes3, 0)

	-- falls back to the stored callback value when the TextBox cannot be found
	local t4, tab4, W4, U4, calls4 = Make(nil, { noTextbox = true })
	find(tab4, "Input", "Image").Config.Callback("777")
	find(tab4, "Button", "Apply background").Config.Callback()
	eq("settings: falls back to callback text", calls4.set[1], "777")

	-- image slider once a custom image is active
	local t5, tab5, W5, U5, calls5, _, _, setActive = Make()
	setActive(true)
	find(tab5, "Slider", "Image transparency").Config.Callback(0.7)
	eq("settings: image slider updates live custom image", calls5.imgTr, 0.7)

	-- options
	local t6, tab6 = Make({ Title = "Prefs", Icon = "cog", Theme = false, Font = false, Transparency = false, Background = false })
	check("settings: options hide sections", find(tab6, "Dropdown", "Theme") == nil and find(tab6, "Dropdown", "Font") == nil
		and find(tab6, "Slider", "Window transparency") == nil and find(tab6, "Input", "Image") == nil and find(tab6, "Paragraph", "Vexari UI v1.7.0") ~= nil)
	local t7, tab7 = Make({ BackgroundTransparency = 5 })
	eq("settings: BackgroundTransparency clamped to 1", find(tab7, "Slider", "Image transparency").Config.Value.Default, 1)
end

---------------------------------------------------------------- report
local out, failed = {}, 0
for _, r in ipairs(R) do
	if not r.ok then failed = failed + 1; out[#out + 1] = "FAIL  " .. r.name .. "   [" .. tostring(r.extra) .. "]" end
end
out[#out + 1] = string.format("%d checks, %d passed, %d failed", #R, #R - failed, failed)
return table.concat(out, "\n")
