local ProfileCard = require("../components/ui/ProfileCard")

local Element = {}

-- Tab:Profile({ Title, Desc, Avatar, Anonymous, Button = { Title, Callback }, Status = { Text, Icon, Color } })
-- See components/ui/ProfileCard.lua.
function Element:New(Config)
	local Card = ProfileCard.New({
		Parent = Config.Parent,
		Folder = Config.Window.Folder,
		Title = Config.Title,
		Desc = Config.Desc,
		Avatar = Config.Avatar,
		Anonymous = Config.Anonymous,
		Button = Config.Button,
		Status = Config.Status,
		Corner = Config.Window.ElementConfig.UICorner,
		LayoutOrder = Config.LayoutOrder,
	})

	local ProfileModule = {
		__type = "Profile",
		ElementFrame = Card.Frame,
		Card = Card,
	}

	function ProfileModule:SetName(...)
		return Card:SetName(...)
	end
	function ProfileModule:SetUsername(...)
		return Card:SetUsername(...)
	end
	function ProfileModule:SetAvatar(...)
		return Card:SetAvatar(...)
	end
	function ProfileModule:SetButton(...)
		return Card:SetButton(...)
	end
	function ProfileModule:SetStatus(...)
		return Card:SetStatus(...)
	end
	function ProfileModule:Destroy()
		Card:Destroy()
	end

	return ProfileModule.__type, ProfileModule
end

return Element
