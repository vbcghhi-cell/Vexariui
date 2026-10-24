local PageHeader = require("../components/ui/PageHeader")

local Element = {}

-- Tab:Header({ Title = "Home", Eyebrow = "Overview", Icon = "home" })
-- See components/ui/PageHeader.lua.
function Element:New(Config)
	local Header = PageHeader.New({
		Parent = Config.Parent,
		Folder = Config.Window.Folder,
		Title = Config.Title,
		Eyebrow = Config.Eyebrow,
		Icon = Config.Icon,
		LayoutOrder = Config.LayoutOrder,
	})

	local HeaderModule = {
		__type = "Header",
		ElementFrame = Header.Frame,
		Header = Header,
	}

	function HeaderModule:SetTitle(...)
		return Header:SetTitle(...)
	end
	function HeaderModule:SetEyebrow(...)
		return Header:SetEyebrow(...)
	end
	function HeaderModule:SetIcon(...)
		return Header:SetIcon(...)
	end
	function HeaderModule:Destroy()
		Header:Destroy()
	end

	return HeaderModule.__type, HeaderModule
end

return Element
