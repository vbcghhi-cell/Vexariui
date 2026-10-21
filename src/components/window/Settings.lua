--[[
	Vexari UI | Built-in Settings tab

	Usage:
		local SettingsTab = Window:CreateSettingsTab({
			Title = "Settings",     -- tab title
			Icon = "settings",      -- tab icon
			Theme = true,           -- theme dropdown
			Font = true,            -- font dropdown
			Transparency = true,    -- window transparency slider
			Background = true,      -- background image (asset id / URL, Apply, Reset)
			BackgroundTransparency = 0.35, -- initial image transparency used by Apply
		})

	Everything here is built from the normal elements (Dropdown, Slider, Input, Button, Paragraph),
	so it follows the active theme / font like the rest of the UI. Calling it twice returns the
	same tab instead of creating a duplicate.
]]

return function(Window, WindUI, SettingsConfig)
	SettingsConfig = SettingsConfig or {}

	if Window.SettingsTab then
		return Window.SettingsTab
	end

	local ShowTheme = SettingsConfig.Theme ~= false
	local ShowFont = SettingsConfig.Font ~= false
	local ShowTransparency = SettingsConfig.Transparency ~= false
	local ShowBackground = SettingsConfig.Background ~= false

	local Tab = Window:Tab({
		Title = SettingsConfig.Title or "Settings",
		Icon = SettingsConfig.Icon or "settings",
	})
	Window.SettingsTab = Tab

	local Initializing = true

	local function Notify(Title, Content, Icon, Duration)
		WindUI:Notify({
			Title = Title,
			Content = Content,
			Icon = Icon,
			Duration = Duration or 3,
		})
	end

	----------------------------------------------------------------------------------------------
	-- Appearance
	----------------------------------------------------------------------------------------------
	if ShowTheme or ShowFont or ShowTransparency then
		Tab:Section({ Title = "Appearance" })
	end

	if ShowTheme then
		local ThemeNames = {}
		for Key in next, WindUI:GetThemes() do
			table.insert(ThemeNames, Key)
		end
		table.sort(ThemeNames)

		-- WindUI.Theme is not updated when a theme is passed through the window Config,
		-- Creator.Theme always is.
		local CurrentKey = "Dark"
		for Key, ThemeTable in next, WindUI:GetThemes() do
			if ThemeTable == WindUI.Creator.Theme then
				CurrentKey = Key
				break
			end
		end

		Tab:Dropdown({
			Title = "Theme",
			Desc = "Colors of the whole window",
			Values = ThemeNames,
			Value = CurrentKey,
			SearchBarEnabled = #ThemeNames > 8,
			Callback = function(Selected)
				if Initializing or typeof(Selected) ~= "string" then
					return
				end
				if WindUI.Creator.Theme == WindUI.Themes[Selected] then
					return
				end

				if WindUI:SetTheme(Selected) then
					Notify("Theme applied", Selected, "palette", 2)
				end
			end,
		})
	end

	if ShowFont then
		Tab:Dropdown({
			Title = "Font",
			Desc = "Applies to every text in the window",
			Values = WindUI:GetFonts(),
			Value = WindUI:GetCurrentFont(),
			Callback = function(Selected)
				if Initializing or typeof(Selected) ~= "string" then
					return
				end
				if WindUI:GetCurrentFont() == Selected then
					return
				end

				if WindUI:SetFont(Selected) then
					Notify("Font applied", Selected, "type", 2)
				end
			end,
		})
	end

	if ShowTransparency then
		Tab:Slider({
			Title = "Window transparency",
			Desc = "0 = solid window",
			Step = 0.1,
			Value = {
				Min = 0,
				Max = 1,
				Default = Window.Transparent and WindUI.TransparencyValue or 0,
			},
			Callback = function(Value)
				if Initializing then
					return
				end
				Window:SetBackgroundTransparency(Value)
			end,
		})
	end

	----------------------------------------------------------------------------------------------
	-- Background image
	----------------------------------------------------------------------------------------------
	if ShowBackground then
		local ImageTransparency = math.clamp(tonumber(SettingsConfig.BackgroundTransparency) or 0.35, 0, 1)
		local ScaleLabels = { Fill = "Crop", Fit = "Fit", Stretch = "Stretch" }
		local ScaleName = "Crop"
		local PendingText = ""

		Tab:Section({ Title = "Background image" })

		local BackgroundInput
		BackgroundInput = Tab:Input({
			Title = "Image",
			Desc = "Roblox image asset id, rbxassetid://id, a roblox.com asset link or an image URL",
			Placeholder = "Asset id or URL",
			Value = "",
			Callback = function(Text)
				PendingText = Text or ""
			end,
		})

		-- The TextBox may still hold text that did not fire its callback yet (e.g. the keyboard was
		-- still open when Apply was tapped), so read it directly and fall back to the stored value.
		local function ReadInputText()
			local Text = PendingText
			pcall(function()
				local Box = BackgroundInput.ElementFrame:FindFirstChildWhichIsA("TextBox", true)
				if Box then
					Text = Box.Text
				end
			end)
			return Text
		end

		Tab:Slider({
			Title = "Image transparency",
			Desc = "0 = fully visible image",
			Step = 0.05,
			Value = {
				Min = 0,
				Max = 1,
				Default = ImageTransparency,
			},
			Callback = function(Value)
				ImageTransparency = Value
				if not Initializing and Window:GetBackground().Active then
					Window:SetBackgroundImageTransparency(Value)
				end
			end,
		})

		local ScaleLabelList = { "Fill", "Fit", "Stretch" }
		Tab:Dropdown({
			Title = "Image scaling",
			Desc = "Fill crops the edges, Fit shows the whole image, Stretch may distort it",
			Values = ScaleLabelList,
			Value = "Fill",
			Callback = function(Selected)
				local Name = ScaleLabels[Selected]
				if Initializing or not Name or Name == ScaleName then
					return
				end

				ScaleName = Name
				Window:SetBackgroundScaleType(Name)
			end,
		})

		local ApplyButton
		ApplyButton = Tab:Button({
			Title = "Apply background",
			Icon = "image",
			Justify = "Center",
			IconAlign = "Left",
			Callback = function()
				local Text = ReadInputText()

				ApplyButton:SetTitle("Loading...")
				task.spawn(function()
					local Ok, Err = Window:SetBackground(Text, {
						Transparency = ImageTransparency,
						ScaleType = ScaleName,
					})

					if not Window.Destroyed then
						ApplyButton:SetTitle("Apply background")

						if Ok then
							Notify("Background applied", "The image is now the window background.", "image", 2)
						elseif typeof(Err) == "string" and Err:sub(1, 9) ~= "Cancelled" then
							Notify("Background not applied", Err, "triangle-alert", 5)
						end
					end
				end)
			end,
		})

		Tab:Button({
			Title = "Reset background",
			Icon = "rotate-ccw",
			Justify = "Center",
			IconAlign = "Left",
			Callback = function()
				Window:ResetBackground()
				BackgroundInput:Set("")
				ApplyButton:SetTitle("Apply background")
				Notify("Background reset", "The original background was restored.", "rotate-ccw", 2)
			end,
		})
	end

	----------------------------------------------------------------------------------------------
	-- About
	----------------------------------------------------------------------------------------------
	Tab:Section({ Title = "About" })
	Tab:Paragraph({
		Title = "Vexari UI v" .. tostring(WindUI.Version),
		Desc = "Based on WindUI by Footagesus (MIT License).",
	})

	Initializing = false

	return Tab
end
