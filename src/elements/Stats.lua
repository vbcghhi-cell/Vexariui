local StatCard = require("../components/ui/StatCard")

local Element = {}

-- Tab:Stats({ Items = { { Key, Title, Value, Color, ValueColor }, ... } })
-- See components/ui/StatCard.lua. Returns an object with SetValue / SetTitle / SetColor / SetValueColor / GetValue.
function Element:New(Config)
	local Card = StatCard.New({
		Parent = Config.Parent,
		Items = Config.Items,
		Corner = Config.Window.ElementConfig.UICorner,
		LayoutOrder = Config.LayoutOrder,
	})

	local StatsModule = {
		__type = "Stats",
		ElementFrame = Card.Frame,
		Card = Card,
	}

	function StatsModule:SetValue(...)
		return Card:SetValue(...)
	end
	function StatsModule:GetValue(...)
		return Card:GetValue(...)
	end
	function StatsModule:SetTitle(...)
		return Card:SetTitle(...)
	end
	function StatsModule:SetColor(...)
		return Card:SetColor(...)
	end
	function StatsModule:SetValueColor(...)
		return Card:SetValueColor(...)
	end
	function StatsModule:Destroy()
		Card:Destroy()
	end

	return StatsModule.__type, StatsModule
end

return Element
