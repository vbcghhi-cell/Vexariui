--[[
	Vexari UI | Chip – small rounded status label with an optional icon
	(e.g. "⌛ Waiting for a round").

	Chip.New({ Text, Icon, Color, Parent, Folder, TextSize, Height, LayoutOrder })
	  Color: Color3 / "#rrggbb" / palette name ("Green"...). Without a color the chip follows the theme.
	  Returns { Frame, SetText, SetIcon, SetColor, SetVisible, Destroy }
]]

local Creator = require("../../modules/Creator")
local Format = require("../../modules/Format")
local New = Creator.New

local Chip = {}

function Chip.New(Options)
	Options = Options or {}
	local TextSize = Options.TextSize or 13
	local Height = Options.Height or 28

	local Label = New("TextLabel", {
		Name = "Label",
		Text = Options.Text or "",
		TextSize = TextSize,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
		BackgroundTransparency = 1,
		AutomaticSize = "XY",
		LayoutOrder = 2,
	})

	local Frame = New("Frame", {
		Name = "Chip",
		AutomaticSize = "X",
		Size = UDim2.new(0, 0, 0, Height),
		LayoutOrder = Options.LayoutOrder or 0,
		Parent = Options.Parent,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UIListLayout", {
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			SortOrder = "LayoutOrder",
			Padding = UDim.new(0, 6),
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 12),
		}),
		Label,
	})

	local ChipModule = { Frame = Frame }
	local IconFrame

	-- A colored chip uses fixed colors. A neutral chip is registered with the theme so it follows
	-- theme changes. Switching between the two detaches / re-attaches the theme registration.
	local function ApplyColor(Color)
		local Accent = Format.Color(Color, nil)

		if Accent then
			Creator.Objects[Frame] = nil
			Creator.Objects[Label] = nil
			Frame.BackgroundColor3 = Accent
			Frame.BackgroundTransparency = 0.85
			Label.TextColor3 = Accent
			Label.TextTransparency = 0
		else
			Frame.BackgroundTransparency = 0.92
			Label.TextTransparency = 0.1
			Creator.AddThemeObject(Frame, { BackgroundColor3 = "Text" })
			Creator.AddThemeObject(Label, { TextColor3 = "Text" })
		end
	end

	function ChipModule:SetText(Text)
		Label.Text = tostring(Text or "")
	end

	function ChipModule:SetIcon(Icon)
		if IconFrame then
			IconFrame:Destroy()
			IconFrame = nil
		end

		if Icon and Icon ~= "" then
			IconFrame = Creator.Image(Icon, Icon, 0, Options.Folder, "Chip", true, true, "ElementIcon")
			IconFrame.Size = UDim2.new(0, TextSize + 1, 0, TextSize + 1)
			IconFrame.LayoutOrder = 1
			IconFrame.Parent = Frame
		end
	end

	function ChipModule:SetColor(Color)
		ApplyColor(Color)
	end

	function ChipModule:SetVisible(Visible)
		Frame.Visible = Visible and true or false
	end

	function ChipModule:Destroy()
		Frame:Destroy()
	end

	ApplyColor(Options.Color)
	ChipModule:SetIcon(Options.Icon)

	return ChipModule
end

return Chip
