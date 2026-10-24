--[[
	Vexari UI | StatCard – one card with several "big value + small label" columns
	(the COINS / GEMS / LEVEL and AUTO FARM / PER HOUR / COLLECTED / UPTIME cards).

	StatCard.New({
		Parent = frame,
		Corner = 16,
		Items = {
			{ Key = "coins", Title = "Coins", Value = 1540, Color = "Yellow" },   -- Color = label color
			{ Key = "farm", Title = "Auto farm", Value = "ON", ValueColor = "Green" },
		},
	})
	Returns { Frame, SetValue(key, value, valueColor?), SetTitle(key, text), SetColor(key, color),
	          SetValueColor(key, color), GetValue(key), Destroy() }
	`key` is the item Key (defaults to its Title) or its position (1, 2, ...).
	Numbers are shown with thousands separators (1540 -> "1,540"); text is shown as it is.
]]

local Creator = require("../../modules/Creator")
local Format = require("../../modules/Format")
local New = Creator.New

local StatCard = {}

-- Fixed color when a color is given, otherwise follow the theme again.
local function ApplyTextColor(Label, Color, ThemeKey)
	local Resolved = Format.Color(Color, nil)
	if Resolved then
		Creator.Objects[Label] = nil
		Label.TextColor3 = Resolved
		return true
	end

	Creator.AddThemeObject(Label, { TextColor3 = ThemeKey })
	return false
end

function StatCard.New(Options)
	Options = Options or {}
	local Items = Options.Items or {}
	local Count = math.max(#Items, 1)

	local Frame = New("Frame", {
		Name = "StatCard",
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
			Transparency = 0.88,
			ApplyStrokeMode = "Border",
			ThemeTag = { Color = "Text" },
		}),
		New("UIListLayout", {
			FillDirection = "Horizontal",
			SortOrder = "LayoutOrder",
			VerticalAlignment = "Center",
		}),
	})

	local Card = { Frame = Frame }
	local Columns = {} -- by position
	local ByKey = {}

	for Index, Item in ipairs(Items) do
		local Key = tostring(Item.Key or Item.Title or Index)

		local ValueLabel = New("TextLabel", {
			Name = "Value",
			Text = Format.Number(Item.Value == nil and "-" or Item.Value),
			TextScaled = true,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Bold),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 0, 30),
			LayoutOrder = 1,
		}, {
			-- shrinks long values instead of letting them spill into the next column
			New("UITextSizeConstraint", { MaxTextSize = 24, MinTextSize = 10 }),
		})

		local TitleLabel = New("TextLabel", {
			Name = "Title",
			Text = tostring(Item.Title or ""):upper(),
			TextSize = 12,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -12, 0, 16),
			TextTruncate = "AtEnd",
			LayoutOrder = 2,
		})

		local Column = New("Frame", {
			Name = "Column" .. Index,
			Size = UDim2.new(1 / Count, 0, 0, 0),
			AutomaticSize = "Y",
			BackgroundTransparency = 1,
			LayoutOrder = Index,
			Parent = Frame,
		}, {
			New("UIListLayout", {
				FillDirection = "Vertical",
				HorizontalAlignment = "Center",
				VerticalAlignment = "Center",
				SortOrder = "LayoutOrder",
				Padding = UDim.new(0, 2),
			}),
			New("UIPadding", {
				PaddingTop = UDim.new(0, 14),
				PaddingBottom = UDim.new(0, 14),
			}),
			ValueLabel,
			TitleLabel,
		})

		if Index < Count then
			New("Frame", {
				Name = "Divider",
				Size = UDim2.new(0, 1, 0.7, 0),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundTransparency = 0.9,
				Parent = Column,
				ThemeTag = { BackgroundColor3 = "Text" },
			})
		end

		local Entry = { Key = Key, Value = Item.Value, ValueLabel = ValueLabel, TitleLabel = TitleLabel }
		Columns[Index] = Entry
		ByKey[Key] = Entry

		-- label: accent color or a dimmed theme text color
		if ApplyTextColor(TitleLabel, Item.Color, "Text") then
			TitleLabel.TextTransparency = 0
		else
			TitleLabel.TextTransparency = 0.45
		end
		ApplyTextColor(ValueLabel, Item.ValueColor, "Text")
	end

	local function Find(Key)
		if typeof(Key) == "number" then
			return Columns[Key]
		end
		return ByKey[tostring(Key)]
	end

	function Card:SetValue(Key, Value, ValueColor)
		local Entry = Find(Key)
		if not Entry then
			return false
		end

		Entry.Value = Value
		Entry.ValueLabel.Text = Format.Number(Value == nil and "-" or Value)
		if ValueColor ~= nil then
			ApplyTextColor(Entry.ValueLabel, ValueColor, "Text")
		end
		return true
	end

	function Card:GetValue(Key)
		local Entry = Find(Key)
		return Entry and Entry.Value or nil
	end

	function Card:SetTitle(Key, Text)
		local Entry = Find(Key)
		if not Entry then
			return false
		end
		Entry.TitleLabel.Text = tostring(Text or ""):upper()
		return true
	end

	function Card:SetColor(Key, Color)
		local Entry = Find(Key)
		if not Entry then
			return false
		end

		if ApplyTextColor(Entry.TitleLabel, Color, "Text") then
			Entry.TitleLabel.TextTransparency = 0
		else
			Entry.TitleLabel.TextTransparency = 0.45
		end
		return true
	end

	function Card:SetValueColor(Key, Color)
		local Entry = Find(Key)
		if not Entry then
			return false
		end
		ApplyTextColor(Entry.ValueLabel, Color, "Text")
		return true
	end

	function Card:Destroy()
		Frame:Destroy()
	end

	return Card
end

return StatCard
