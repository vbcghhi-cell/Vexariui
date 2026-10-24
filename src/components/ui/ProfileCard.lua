--[[
	Vexari UI | ProfileCard – avatar, display name, @username, an optional button on the right
	and an optional status chip underneath ("⌛ Waiting for a round").

	ProfileCard.New({
		Parent = frame, Folder = "myhub",
		Title = "Display name",         -- default: the local player's display name
		Desc = "@username",             -- default: "@" .. the local player's name
		Avatar = 1234567,               -- user id (headshot) | image string | nil = local player
		Anonymous = false,              -- hides name + avatar
		Button = { Title = "Lobby", Callback = function() end },
		Status = { Text = "Waiting for a round", Icon = "hourglass", Color = "Green" },
	})
	Returns { Frame, SetName, SetUsername, SetAvatar, SetButton, SetStatus, Destroy }
]]

local Creator = require("../../modules/Creator")
local Chip = require("./Chip")
local New = Creator.New
local Tween = Creator.Tween

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

local Players = cloneref(game:GetService("Players"))

local ProfileCard = {}

local AvatarSize = 52

function ProfileCard.New(Options)
	Options = Options or {}
	local LocalPlayer = Players.LocalPlayer
	local Anonymous = Options.Anonymous == true
	local ButtonReserve = Options.Button and 120 or 0

	local function DefaultName()
		if Anonymous then
			return "Anonymous"
		end
		return LocalPlayer and LocalPlayer.DisplayName or "Player"
	end

	local function DefaultUsername()
		if Anonymous then
			return "@anonymous"
		end
		return "@" .. (LocalPlayer and LocalPlayer.Name or "player")
	end

	local Avatar = New("ImageLabel", {
		Name = "Avatar",
		Size = UDim2.new(0, AvatarSize, 0, AvatarSize),
		BackgroundTransparency = 0.93,
		Image = "",
		LayoutOrder = 1,
		ThemeTag = { BackgroundColor3 = "Text" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UIStroke", {
			Thickness = 2,
			Transparency = 0.6,
			ApplyStrokeMode = "Border",
			ThemeTag = { Color = "Text" },
		}),
	})

	local NameLabel = New("TextLabel", {
		Name = "DisplayName",
		Text = Options.Title or DefaultName(),
		TextSize = 18,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		TextXAlignment = "Left",
		TextTruncate = "AtEnd",
		LayoutOrder = 1,
		ThemeTag = { TextColor3 = "Text" },
	})

	local UserLabel = New("TextLabel", {
		Name = "Username",
		Text = Options.Desc or DefaultUsername(),
		TextSize = 14,
		TextTransparency = 0.5,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 18),
		TextXAlignment = "Left",
		TextTruncate = "AtEnd",
		LayoutOrder = 2,
		ThemeTag = { TextColor3 = "Text" },
	})

	-- Names fill the row minus the avatar, the gaps and the room reserved for the button
	local function NamesSize(Reserve)
		return UDim2.new(1, -(AvatarSize + 28 + Reserve), 1, 0)
	end

	local Names = New("Frame", {
		Name = "Names",
		BackgroundTransparency = 1,
		Size = NamesSize(ButtonReserve),
		LayoutOrder = 2,
	}, {
		New("UIListLayout", {
			FillDirection = "Vertical",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 2),
		}),
		NameLabel,
		UserLabel,
	})

	local TopRow = New("Frame", {
		Name = "TopRow",
		Size = UDim2.new(1, 0, 0, AvatarSize),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	}, {
		New("UIListLayout", {
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 14),
		}),
		Avatar,
		Names,
	})

	-- the button sits in its own holder so it can be right-aligned inside the horizontal layout
	local ButtonHolder = New("Frame", {
		Name = "ButtonHolder",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, ButtonReserve, 1, 0),
		LayoutOrder = 3,
		Parent = TopRow,
	})

	local StatusRow = New("Frame", {
		Name = "StatusRow",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = "Y",
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Visible = false,
	}, {
		New("UIListLayout", { FillDirection = "Horizontal", SortOrder = "LayoutOrder" }),
	})

	local Frame = New("Frame", {
		Name = "ProfileCard",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = "Y",
		LayoutOrder = Options.LayoutOrder or 0,
		Parent = Options.Parent,
		ThemeTag = {
			BackgroundColor3 = "ElementBackground",
			BackgroundTransparency = "ElementBackgroundTransparency",
		},
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, Options.Corner or 16) }),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.8,
			ApplyStrokeMode = "Border",
			ThemeTag = { Color = "Text" },
		}),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
		}),
		New("UIListLayout", {
			FillDirection = "Vertical",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 12),
		}),
		TopRow,
		StatusRow,
	})

	local Card = { Frame = Frame }

	----------------------------------------------------------------------------------------------
	-- avatar
	----------------------------------------------------------------------------------------------
	local AvatarRequest = 0

	function Card:SetAvatar(Source)
		AvatarRequest = AvatarRequest + 1
		local Request = AvatarRequest

		if typeof(Source) == "string" and Source ~= "" then
			Avatar.Image = Source
			return
		end

		local UserId = typeof(Source) == "number" and Source or nil
		if Anonymous then
			UserId = 1
		elseif not UserId and LocalPlayer then
			UserId = LocalPlayer.UserId
		end
		if not UserId then
			return
		end

		task.spawn(function()
			local Ok, Content = pcall(function()
				local Image = Players:GetUserThumbnailAsync(
					UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size150x150
				)
				return Image
			end)

			-- ignore the answer when a newer SetAvatar call replaced this one or the card is gone
			if Ok and Request == AvatarRequest and Avatar.Parent then
				Avatar.Image = Content
			end
		end)
	end

	function Card:SetName(Text)
		NameLabel.Text = tostring(Text or "")
	end

	function Card:SetUsername(Text)
		UserLabel.Text = tostring(Text or "")
	end

	----------------------------------------------------------------------------------------------
	-- right-hand button
	----------------------------------------------------------------------------------------------
	local ButtonFrame
	local ButtonCallback

	function Card:SetButton(Button)
		if ButtonFrame then
			ButtonFrame:Destroy()
			ButtonFrame = nil
		end
		ButtonCallback = nil

		if not Button then
			ButtonHolder.Size = UDim2.new(0, 0, 1, 0)
			Names.Size = NamesSize(0)
			return
		end
		ButtonCallback = Button.Callback
		ButtonHolder.Size = UDim2.new(0, 120, 1, 0)
		Names.Size = NamesSize(120)

		ButtonFrame = New("TextButton", {
			Name = "Button",
			Text = tostring(Button.Title or "Button"):upper(),
			TextSize = 13,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Bold),
			AutomaticSize = "X",
			Size = UDim2.new(0, 0, 0, 32),
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			BackgroundTransparency = 0.82,
			AutoButtonColor = false,
			Parent = ButtonHolder,
			ThemeTag = {
				BackgroundColor3 = "Text",
				TextColor3 = "Text",
			},
		}, {
			New("UICorner", { CornerRadius = UDim.new(1, 0) }),
			New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
		})

		Creator.AddSignal(ButtonFrame.MouseEnter, function()
			Tween(ButtonFrame, 0.12, { BackgroundTransparency = 0.7 }):Play()
		end)
		Creator.AddSignal(ButtonFrame.MouseLeave, function()
			Tween(ButtonFrame, 0.12, { BackgroundTransparency = 0.82 }):Play()
		end)
		Creator.AddSignal(ButtonFrame.MouseButton1Click, function()
			if ButtonCallback then
				Creator.SafeCallback(ButtonCallback)
			end
		end)
	end

	----------------------------------------------------------------------------------------------
	-- status chip
	----------------------------------------------------------------------------------------------
	local StatusChip

	-- Card:SetStatus("Waiting for a round", "hourglass", "Green")  |  Card:SetStatus(nil) hides it
	function Card:SetStatus(Text, Icon, Color)
		if typeof(Text) == "table" then
			Text, Icon, Color = Text.Text, Text.Icon, Text.Color
		end

		if Text == nil or Text == "" then
			if StatusChip then
				StatusChip:Destroy()
				StatusChip = nil
			end
			StatusRow.Visible = false
			return
		end

		if not StatusChip then
			StatusChip = Chip.New({ Parent = StatusRow, Folder = Options.Folder })
		end
		StatusChip:SetText(Text)
		StatusChip:SetIcon(Icon)
		StatusChip:SetColor(Color)
		StatusRow.Visible = true
	end

	function Card:Destroy()
		AvatarRequest = AvatarRequest + 1
		Frame:Destroy()
	end

	Card:SetAvatar(Options.Avatar)
	Card:SetButton(Options.Button)
	if Options.Status then
		Card:SetStatus(Options.Status)
	end

	return Card
end

return ProfileCard
