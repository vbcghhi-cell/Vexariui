--[[
	Vexari UI | Font registry

	Keeps a named list of fonts that can be selected at runtime (see WindUI:SetFont / WindUI:GetFonts).

	Only fonts that Roblox itself ships are registered by default. Their family paths are NOT
	hard-coded: they are read from `Font.fromEnum(Enum.Font.X).Family` at runtime, so a font that
	does not exist in the running client is skipped instead of being registered with a broken path.
]]

local Fonts = {
	List = {}, -- ordered array of { Name = string, Family = string }
	ByName = {},
	Current = "Default",
}

-- { display name, Enum.Font member name }
-- Chosen for UI use: readable at 12-18px and without extreme glyph widths (no display / handwriting faces).
local BuiltInCandidates = {
	{ "Gotham", "Gotham" },
	{ "Source Sans", "SourceSans" },
	{ "Montserrat", "Montserrat" },
	{ "Ubuntu", "Ubuntu" },
	{ "Nunito", "Nunito" },
	{ "Roboto", "Roboto" },
	{ "Arial", "Arial" },
	{ "Josefin Sans", "JosefinSans" },
	{ "Merriweather", "Merriweather" },
	{ "Roboto Mono", "RobotoMono" },
}

function Fonts.Add(Name, Family)
	if typeof(Name) ~= "string" or Name == "" or typeof(Family) ~= "string" or Family == "" then
		return false
	end

	if Fonts.ByName[Name] then
		Fonts.ByName[Name].Family = Family
		return true
	end

	local Entry = { Name = Name, Family = Family }
	table.insert(Fonts.List, Entry)
	Fonts.ByName[Name] = Entry
	return true
end

function Fonts.Init(DefaultFamily)
	table.clear(Fonts.List)
	table.clear(Fonts.ByName)

	Fonts.Add("Default", DefaultFamily)
	Fonts.Current = "Default"

	for _, Candidate in ipairs(BuiltInCandidates) do
		local Ok, Family = pcall(function()
			return Font.fromEnum(Enum.Font[Candidate[2]]).Family
		end)

		if Ok and typeof(Family) == "string" and Family ~= "" then
			Fonts.Add(Candidate[1], Family)
		end
	end
end

function Fonts.GetNames()
	local Names = {}
	for _, Entry in ipairs(Fonts.List) do
		table.insert(Names, Entry.Name)
	end
	return Names
end

-- Accepts a registered name ("Gotham") or a raw font family path / asset id ("rbxassetid://...").
-- Returns family, name (name is nil for raw ids that are not registered).
function Fonts.Resolve(NameOrFamily)
	if typeof(NameOrFamily) ~= "string" or NameOrFamily == "" then
		return nil, nil
	end

	local Entry = Fonts.ByName[NameOrFamily]
	if Entry then
		return Entry.Family, Entry.Name
	end

	for _, Other in ipairs(Fonts.List) do
		if Other.Family == NameOrFamily then
			return Other.Family, Other.Name
		end
	end

	return NameOrFamily, nil
end

return Fonts
