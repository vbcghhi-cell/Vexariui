--[[
	Vexari UI | PageHeader – icon box + small caps line + big page title
	("OVERVIEW / Home").

	PageHeader.New({ Parent, Folder, Title = "Home", Eyebrow = "Overview", Icon = "home" })
	Returns { Frame, SetTitle, SetEyebrow, SetIcon, Destroy }
]]

local Creator = require("../../modules/Creator")
local New = Creator.New

local PageHeader = {}

local BoxSize = 46

function PageHeader.New(Options)
	Options = Options or {}

	local IconBox = New("Frame", {
		Name = "IconBox",
		Size = UDim2.new(0, BoxSize, 0, BoxSize),
		LayoutOrder = 1,
		ThemeTag = {
			BackgroundColor3 = "ElementBackground",
			BackgroundTransparency = "ElementBackgroundTransparency",
		},
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 14) }),
		New("UIStroke", {
			Thickness = 1,
			Transparency = 0.85,
			ApplyStrokeMode = "Border",
			ThemeTag = { Color = "Text" },
		}),
	})

	local EyebrowLabel = New("TextLabel", {
		Name = "Eyebrow",
		Text = tostring(Options.Eyebrow or ""):upper(),
		TextSize = 12,
		TextTransparency = 0.45,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 14),
		TextXAlignment = "Left",
		TextTruncate = "AtEnd",
		LayoutOrder = 1,
		Visible = Options.Eyebrow ~= nil and Options.Eyebrow ~= "",
		ThemeTag = { TextColor3 = "Text" },
	})

	local TitleLabel = New("TextLabel", {
		Name = "Title",
		Text = tostring(Options.Title or ""),
		TextSize = 28,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Bold),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 32),
		TextXAlignment = "Left",
		TextTruncate = "AtEnd",
		LayoutOrder = 2,
		ThemeTag = { TextColor3 = "Text" },
	})

	local Texts = New("Frame", {
		Name = "Texts",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -(BoxSize + 14), 1, 0),
		LayoutOrder = 2,
	}, {
		New("UIListLayout", {
			FillDirection = "Vertical",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 0),
		}),
		New("UIPadding", { PaddingLeft = UDim.new(0, 2) }),
		EyebrowLabel,
		TitleLabel,
	})

	local Frame = New("Frame", {
		Name = "PageHeader",
		Size = UDim2.new(1, 0, 0, BoxSize + 6),
		BackgroundTransparency = 1,
		LayoutOrder = Options.LayoutOrder or 0,
		Parent = Options.Parent,
	}, {
		New("UIListLayout", {
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 14),
		}),
		IconBox,
		Texts,
	})

	local Header = { Frame = Frame }
	local IconFrame

	function Header:SetTitle(Text)
		TitleLabel.Text = tostring(Text or "")
	end

	function Header:SetEyebrow(Text)
		local Value = tostring(Text or "")
		EyebrowLabel.Text = Value:upper()
		EyebrowLabel.Visible = Value ~= ""
	end

	function Header:SetIcon(Icon)
		if IconFrame then
			IconFrame:Destroy()
			IconFrame = nil
		end

		if Icon and Icon ~= "" then
			IconFrame = Creator.Image(Icon, Icon, 0, Options.Folder, "PageHeader", true, true, "ElementIcon")
			IconFrame.Size = UDim2.new(0, 22, 0, 22)
			IconFrame.AnchorPoint = Vector2.new(0.5, 0.5)
			IconFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
			IconFrame.Parent = IconBox
		end
	end

	function Header:Destroy()
		Frame:Destroy()
	end

	Header:SetIcon(Options.Icon)

	return Header
end

return PageHeader
