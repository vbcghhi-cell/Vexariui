--[[
	Vexari UI | small formatting helpers used by the dashboard components
	(components/ui/StatCard, ProfileCard, Chip, Status)
]]

local Format = {}

-- Accent colors used for stat labels, dots and chips. Names are case-insensitive.
Format.Palette = {
	yellow = "#fbbf24",
	blue = "#60a5fa",
	purple = "#a78bfa",
	green = "#34d399",
	orange = "#fb923c",
	red = "#f87171",
	pink = "#f472b6",
	cyan = "#22d3ee",
	white = "#ffffff",
	gray = "#9ca3af",
}

-- Accepts a Color3, "#rrggbb" / "rrggbb", or a palette name ("Yellow", "green", ...).
-- Returns a Color3, or Fallback when the value is not understood.
function Format.Color(Value, Fallback)
	if typeof(Value) == "Color3" then
		return Value
	end

	if typeof(Value) == "string" then
		local Hex = Format.Palette[Value:lower()] or Value
		Hex = Hex:gsub("^#", "")

		if #Hex == 6 and not Hex:find("%X") then
			return Color3.fromHex(Hex)
		end
	end

	return Fallback
end

-- 1540 -> "1,540", 1234567.5 -> "1,234,567.5". Anything that is not a number is returned as text.
function Format.Number(Value)
	if typeof(Value) ~= "number" then
		return tostring(Value)
	end
	if Value ~= Value or Value == math.huge or Value == -math.huge then
		return tostring(Value)
	end

	local Text = string.format("%.2f", Value)
	Text = Text:gsub("%.?0+$", "")

	local Sign, Integer, Fraction = Text:match("^(-?)(%d+)(.*)$")
	if not Integer then
		return Text
	end

	local Reversed = Integer:reverse()
	Reversed = Reversed:gsub("(%d%d%d)", "%1,")
	Integer = Reversed:reverse()
	Integer = Integer:gsub("^,", "")

	return Sign .. Integer .. Fraction
end

return Format
