--[[
	Vexari UI | Window background image manager

	Adds a runtime-changeable background image on top of the window's own Config.Background system
	(see components/window/Init.lua). The original background (image / video / gradient from the
	window Config) is never destroyed: it is only hidden while a custom image is active, so Reset can
	bring it back exactly as it was.

	Input accepted by Background.Parse:
	  * 123456789                              (number)
	  * "123456789"                            (digits only)
	  * "rbxassetid://123456789"
	  * "rbxthumb://type=Asset&id=123&w=420&h=420"
	  * "rbxasset://..."                       (built-in client content)
	  * roblox.com / *.roblox.com links that carry an asset id
	  * any other http(s) image URL            (only on executors with writefile + getcustomasset)
]]

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local ContentProvider = cloneref(game:GetService("ContentProvider"))

local Background = {
	PreloadTimeout = 8, -- seconds to wait for ContentProvider:PreloadAsync
	VerifyTimeout = 4, -- seconds to wait for ImageLabel.IsLoaded after the image was assigned
	MaxDownloadBytes = 10 * 1024 * 1024,
}

Background.ScaleTypes = {
	Crop = Enum.ScaleType.Crop, -- fills the window, may cut the edges
	Fit = Enum.ScaleType.Fit, -- whole image visible, may leave empty bars
	Stretch = Enum.ScaleType.Stretch, -- fills the window, may distort
}

----------------------------------------------------------------------------------------------------
-- Input parsing
----------------------------------------------------------------------------------------------------

local function RobloxAsset(DigitString)
	local Clean = DigitString:gsub("^0+", "")
	if Clean == "" or #Clean > 19 then
		return nil, "That is not a valid Roblox asset id."
	end

	return { Kind = "roblox", Content = "rbxassetid://" .. Clean, Id = Clean }
end

-- Returns { Kind = "roblox" | "builtin" | "http", Content = string, Id = string? } or nil, errorMessage
function Background.Parse(Input)
	local InputType = typeof(Input)

	if InputType == "number" then
		if Input ~= Input or Input < 1 or Input % 1 ~= 0 or Input > 9007199254740991 then
			return nil, "The asset id must be a positive whole number."
		end
		return RobloxAsset(string.format("%d", Input))
	end

	if InputType ~= "string" then
		return nil, "Enter a Roblox image asset id or an image URL."
	end

	local Text = Input:gsub("^%s+", "")
	Text = Text:gsub("%s+$", "")
	Text = Text:match("^[\"'](.-)[\"']$") or Text

	if Text == "" then
		return nil, "Enter a Roblox image asset id or an image URL."
	end
	if #Text > 2048 then
		return nil, "The input is too long."
	end
	if Text:find("%s") then
		return nil, "The input must not contain spaces."
	end

	local Lower = Text:lower()

	if Lower:match("^video:") then
		return nil, "Video backgrounds can only be set through the window Config.Background."
	end

	local Digits = Text:match("^%d+$")
	if Digits then
		return RobloxAsset(Digits)
	end

	local AssetId = Lower:match("^rbxassetid://(%d+)$")
	if AssetId then
		return RobloxAsset(AssetId)
	end

	if Lower:match("^rbxthumb://") then
		if Lower:match("^rbxthumb://type=%a+&id=%d+") then
			return { Kind = "roblox", Content = Text }
		end
		return nil, "Invalid rbxthumb:// link."
	end

	if Lower:match("^rbxasset://") then
		return { Kind = "builtin", Content = Text }
	end

	if Lower:match("^https?://") then
		local Host = Lower:match("^https?://([^/%?#]+)")
		if not Host or not Host:find("%.") then
			return nil, "That URL is not valid."
		end

		if Host == "roblox.com" or Host:match("%.roblox%.com$") then
			local Found = Lower:match("[%?&]id=(%d+)")
				or Lower:match("[%?&]assetid=(%d+)")
				or Lower:match("/library/(%d+)")
				or Lower:match("/asset/(%d+)")
				or Lower:match("/catalog/(%d+)")

			if Found then
				return RobloxAsset(Found)
			end

			return nil, "Could not find an asset id in that Roblox link."
		end

		return { Kind = "http", Content = Text }
	end

	return nil, "Unsupported input. Use an asset id, rbxassetid://id, a roblox.com asset link or an image URL."
end

----------------------------------------------------------------------------------------------------
-- External (non-Roblox) images: download, validate, convert to a client asset
----------------------------------------------------------------------------------------------------

local function Hash(Text)
	local Value = 5381
	for Index = 1, #Text do
		Value = (Value * 33 + string.byte(Text, Index)) % 4294967296
	end
	return string.format("%08x", Value)
end

local function DetectImage(Body)
	if #Body < 12 then
		return nil, "The download is empty or truncated."
	end
	if Body:sub(1, 8) == "\137PNG\r\n\26\n" then
		return "png"
	end
	if Body:sub(1, 3) == "\255\216\255" then
		return "jpg"
	end
	if Body:sub(1, 4) == "RIFF" and Body:sub(9, 12) == "WEBP" then
		return "webp"
	end
	if Body:sub(1, 2) == "BM" then
		return "bmp"
	end
	if Body:sub(1, 3) == "GIF" then
		return nil, "GIF images are not supported by Roblox."
	end

	return nil, "The URL did not return a PNG, JPEG, WebP or BMP image."
end

local function Fetch(Url, Creator)
	local Ok, Body = pcall(function()
		return game:HttpGet(Url)
	end)
	if Ok and typeof(Body) == "string" then
		return Body
	end

	if Creator and Creator.Request then
		local RequestOk, Response = pcall(Creator.Request, {
			Url = Url,
			Method = "GET",
			Headers = { ["User-Agent"] = "Roblox/Exploit" },
		})

		if RequestOk and typeof(Response) == "table" and typeof(Response.Body) == "string" then
			if Response.StatusCode == nil or Response.StatusCode == 200 then
				return Response.Body
			end
			return nil, "The server answered with HTTP " .. tostring(Response.StatusCode) .. "."
		end
	end

	return nil, "Could not download the image."
end

-- Returns a client content string (rbxasset://...) or nil, errorMessage
function Background.Download(Url, Folder, Creator)
	if not (writefile and isfile and getcustomasset) then
		return nil,
			"Loading images from an external URL needs an executor with writefile and getcustomasset. Use a Roblox asset id instead."
	end

	local Root = Folder or "Temp"
	local Dir = Root .. "/assets"
	local Prefix = Dir .. "/.vexari_bg_" .. Hash(Url) .. "."

	pcall(function()
		if makefolder and isfolder then
			if not isfolder(Root) then
				makefolder(Root)
			end
			if not isfolder(Dir) then
				makefolder(Dir)
			end
		end
	end)

	for _, Extension in ipairs({ "png", "jpg", "webp", "bmp" }) do
		local Ok, Exists = pcall(isfile, Prefix .. Extension)
		if Ok and Exists then
			local AssetOk, Asset = pcall(getcustomasset, Prefix .. Extension)
			if AssetOk and typeof(Asset) == "string" and Asset ~= "" then
				return Asset
			end
		end
	end

	local Body, FetchError = Fetch(Url, Creator)
	if not Body then
		return nil, FetchError
	end
	if #Body > Background.MaxDownloadBytes then
		return nil, "The image is larger than 10 MB."
	end

	local Extension, Reason = DetectImage(Body)
	if not Extension then
		return nil, Reason
	end

	local Path = Prefix .. Extension
	local WriteOk, WriteError = pcall(writefile, Path, Body)
	if not WriteOk then
		return nil, "Could not save the image: " .. tostring(WriteError)
	end

	local AssetOk, Asset = pcall(getcustomasset, Path)
	if not AssetOk or typeof(Asset) ~= "string" or Asset == "" then
		return nil, "The executor could not turn the downloaded file into an asset."
	end

	return Asset
end

----------------------------------------------------------------------------------------------------
-- Loading checks
----------------------------------------------------------------------------------------------------

local CancelledMessage = "Cancelled: a newer background request replaced this one."

-- Warms the asset cache and reports whether Roblox could fetch it. Yields.
-- Returns true, or false + reason. A missing callback result is treated as "unknown" (true).
-- `IsCancelled` (optional) is polled so a replaced request stops waiting immediately.
local function Preload(Content, IsCancelled)
	local Finished = false
	local Status = nil

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ Content }, function(_, FetchStatus)
				Status = FetchStatus
			end)
		end)
		Finished = true
	end)

	local Started = os.clock()
	while not Finished and os.clock() - Started < Background.PreloadTimeout do
		if IsCancelled and IsCancelled() then
			return false, CancelledMessage
		end
		task.wait(0.05)
	end

	if not Finished then
		return false, "Timed out while loading the image."
	end
	if Status == Enum.AssetFetchStatus.Failure then
		return false, "Roblox could not load that asset (it may not exist, be private, or be moderated)."
	end
	if Status == Enum.AssetFetchStatus.TimedOut then
		return false, "Timed out while loading the image."
	end

	return true
end

local function WaitForLoaded(Label, IsCancelled)
	local Started = os.clock()
	while os.clock() - Started < Background.VerifyTimeout do
		if not Label.Parent or (IsCancelled and IsCancelled()) then
			return false
		end
		if Label.IsLoaded then
			return true
		end
		task.wait(0.1)
	end
	return Label.Parent ~= nil and Label.IsLoaded
end

-- Many people paste a Decal id (Creator Store) instead of the Image id behind it. On executors
-- game:GetObjects can read the decal and give us the real image content. Best effort only.
local function ResolveDecal(Id)
	local Ok, Texture = pcall(function()
		local Objects = game:GetObjects("rbxassetid://" .. Id)
		local Root = Objects and Objects[1]
		if not Root then
			return nil
		end

		local Found
		if Root:IsA("Decal") or Root:IsA("Texture") then
			Found = Root
		else
			Found = Root:FindFirstChildWhichIsA("Decal", true) or Root:FindFirstChildWhichIsA("Texture", true)
		end

		local Value = Found and Found.Texture
		Root:Destroy()
		return Value
	end)

	if Ok and typeof(Texture) == "string" and Texture ~= "" then
		return Texture
	end
	return nil
end

----------------------------------------------------------------------------------------------------
-- Manager
----------------------------------------------------------------------------------------------------

-- Options:
--   Host                 Frame the image is parented to (Window.UIElements.Main.Background)
--   Original             The window's own background instance from Config.Background (may be nil)
--   OriginalTransparency number, the BackgroundImageTransparency the window started with
function Background.New(Window, Creator, Options)
	local New = Creator.New
	local Tween = Creator.Tween

	local Manager = {
		Active = false,
		Source = nil, -- what the user typed
		Content = nil, -- what is assigned to ImageLabel.Image
		ScaleType = "Crop",
		Label = nil,
		Token = 0,
	}

	local HiddenOriginal = false
	local HiddenGradient = false

	local function IsAlive()
		return not Window.Destroyed and Options.Host and Options.Host.Parent ~= nil
	end

	local function GetShownTransparency()
		if Window.Closed then
			return 1
		end
		return Window.BackgroundImageTransparency
	end

	local function EnsureLabel()
		if Manager.Label and Manager.Label.Parent then
			return Manager.Label
		end

		Manager.Label = New("ImageLabel", {
			Name = "VexariBackground",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Image = "",
			ImageTransparency = 1,
			ScaleType = Background.ScaleTypes[Manager.ScaleType],
			-- Below every other child of the window background (drag bar, resize handle, gradient)
			-- so the image can never cover or block them. Everything interactive lives in the
			-- window's Main frame, which has a much higher ZIndex.
			ZIndex = 0,
			-- Visible (but fully transparent) so Roblox really loads the image while we verify it.
			-- It only becomes opaque once the image was confirmed.
			Visible = true,
			Parent = Options.Host,
		}, {
			New("UICorner", {
				CornerRadius = UDim.new(0, Window.UICorner),
			}),
		})

		return Manager.Label
	end

	local function HideOriginal()
		local Original = Options.Original
		if Original and Original.Parent and Original.Visible then
			Original.Visible = false
			if Original:IsA("VideoFrame") then
				pcall(function()
					Original:Pause()
				end)
			end
			HiddenOriginal = true
		end

		local Gradient = Window.UIElements.BackgroundGradient
		if Gradient and Gradient.Parent and Gradient.Visible then
			Gradient.Visible = false
			HiddenGradient = true
		end
	end

	local function RestoreOriginal()
		local Original = Options.Original
		if HiddenOriginal and Original and Original.Parent then
			Original.Visible = true
			if Original:IsA("VideoFrame") and not Window.Closed then
				pcall(function()
					Original:Play()
				end)
			end
		end
		HiddenOriginal = false

		local Gradient = Window.UIElements.BackgroundGradient
		if HiddenGradient and Gradient and Gradient.Parent then
			Gradient.Visible = true
		end
		HiddenGradient = false
	end

	local function DestroyLabel()
		if Manager.Label then
			Manager.Label:Destroy()
			Manager.Label = nil
		end
	end

	-- Loads `Content` into the label and checks that Roblox really displays it.
	-- Returns true or false + reason. The label keeps its previous image when this fails.
	local function Assign(Label, Content, Token)
		local Previous = Label.Image

		Label.Image = Content
		local Loaded = WaitForLoaded(Label, function()
			return Token ~= Manager.Token
		end)

		if Token ~= Manager.Token then
			return false, CancelledMessage
		end

		if not Loaded then
			Label.Image = Previous
			return false, "The asset loaded but is not a displayable image. If this is a Decal id, use the Image id instead."
		end

		return true
	end

	-- Applies a background image. Yields until the image is loaded or failed.
	-- Options: Transparency (0-1), ScaleType ("Crop" | "Fit" | "Stretch")
	-- Returns true, or false + a message that is safe to show to the user.
	function Manager:Apply(Source, ApplyOptions)
		ApplyOptions = ApplyOptions or {}

		if not IsAlive() then
			return false, "The window no longer exists."
		end

		local Parsed, ParseError = Background.Parse(Source)
		if not Parsed then
			return false, ParseError
		end

		Manager.Token = Manager.Token + 1
		local Token = Manager.Token

		local function IsCancelled()
			return Token ~= Manager.Token or not IsAlive()
		end

		local Content = Parsed.Content

		if Parsed.Kind == "http" then
			local Asset, DownloadError = Background.Download(Parsed.Content, Window.Folder, Creator)
			if not Asset then
				return false, DownloadError
			end
			Content = Asset
		end

		if IsCancelled() then
			return false, CancelledMessage
		end

		if Parsed.Kind ~= "builtin" then
			local Reachable, Reason = Preload(Content, IsCancelled)
			if not Reachable then
				return false, Reason
			end
			if IsCancelled() then
				return false, CancelledMessage
			end
		end

		local Label = EnsureLabel()
		local WasActive = Manager.Active

		if ApplyOptions.ScaleType and Background.ScaleTypes[ApplyOptions.ScaleType] then
			Manager.ScaleType = ApplyOptions.ScaleType
			Label.ScaleType = Background.ScaleTypes[Manager.ScaleType]
		end

		local Ok, Reason = Assign(Label, Content, Token)

		if not Ok and Parsed.Id and Token == Manager.Token then
			-- maybe a Decal id: try to read the real image id out of it
			local Texture = ResolveDecal(Parsed.Id)
			if Texture and Token == Manager.Token and Label.Parent then
				Content = Texture
				Ok, Reason = Assign(Label, Content, Token)
			end
		end

		if not Ok then
			if not WasActive and Token == Manager.Token then
				DestroyLabel()
			end
			return false, Reason
		end

		if ApplyOptions.Transparency ~= nil then
			Window:SetBackgroundImageTransparency(ApplyOptions.Transparency)
		end

		HideOriginal()

		Label.Visible = true
		Label.ImageTransparency = GetShownTransparency()

		Manager.Active = true
		Manager.Source = typeof(Source) == "string" and Source or tostring(Source)
		Manager.Content = Content

		return true
	end

	-- Removes the custom image and brings the window's original background back.
	function Manager:Reset()
		Manager.Token = Manager.Token + 1 -- cancels any load that is still running

		DestroyLabel()
		RestoreOriginal()

		Manager.Active = false
		Manager.Source = nil
		Manager.Content = nil

		if Options.OriginalTransparency ~= nil then
			Window.BackgroundImageTransparency = Options.OriginalTransparency
		end

		local Original = Options.Original
		if Original and Original.Parent and Original:IsA("ImageLabel") and not Window.Closed then
			Original.ImageTransparency = Window.BackgroundImageTransparency
		end

		return true
	end

	function Manager:SetScaleType(Name)
		local Value = Background.ScaleTypes[Name]
		if not Value then
			return false, "Unknown scale type. Use Crop, Fit or Stretch."
		end

		Manager.ScaleType = Name
		if Manager.Label then
			Manager.Label.ScaleType = Value
		end
		return true
	end

	-- Used by Window:SetBackgroundImageTransparency
	function Manager:ApplyTransparency()
		if Manager.Label and Manager.Active and not Window.Closed then
			Manager.Label.ImageTransparency = Window.BackgroundImageTransparency
		end
	end

	-- Window open / close animations (see Window:Open and Window:Close)
	function Manager:OnOpen()
		if Manager.Label and Manager.Active then
			Tween(Manager.Label, 0.2, {
				ImageTransparency = Window.BackgroundImageTransparency,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end
	end

	function Manager:OnClose()
		if Manager.Label and Manager.Active then
			Tween(Manager.Label, 0.3, {
				ImageTransparency = 1,
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
		end
	end

	function Manager:GetState()
		return {
			Active = Manager.Active,
			Source = Manager.Source,
			Content = Manager.Content,
			ScaleType = Manager.ScaleType,
			Transparency = Window.BackgroundImageTransparency,
		}
	end

	function Manager:Destroy()
		Manager.Token = Manager.Token + 1
		DestroyLabel()
	end

	return Manager
end

return Background
