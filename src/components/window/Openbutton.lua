local OpenButton = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween
local Status = require("../ui/Status")


local cloneref = (cloneref or clonereference or function(instance) return instance end)


local UserInputService = cloneref(game:GetService("UserInputService"))


function OpenButton.New(Window)
    local OpenButtonMain = {
        Button = nil
    }
    
    local Icon
    
    
    
    -- Icon = New("ImageLabel", {
    --     Image = "",
    --     Size = UDim2.new(0,22,0,22),
    --     Position = UDim2.new(0.5,0,0.5,0),
    --     LayoutOrder = -1,
    --     AnchorPoint = Vector2.new(0.5,0.5),
    --     BackgroundTransparency = 1,
    --     Name = "Icon"
    -- })

    local Title = New("TextLabel", {
        Text = Window.Title,
        TextSize = 17,
        FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
        BackgroundTransparency = 1,
        AutomaticSize = "XY",
        LayoutOrder = 1,
    })

    -- Vexari UI: the title and the optional "fps / ms" row are stacked vertically
    local TextStack = New("Frame", {
        Name = "TextStack",
        BackgroundTransparency = 1,
        AutomaticSize = "XY",
        Size = UDim2.new(0,0,0,0),
    }, {
        New("UIListLayout", {
            FillDirection = "Vertical",
            SortOrder = "LayoutOrder",
            HorizontalAlignment = "Left",
            Padding = UDim.new(0, 1),
        }),
        Title,
    })

    local DragIconData = Creator.Icon("move")
    local Drag = New("Frame", {
        Size = UDim2.new(0,44-8,0,44-8),
        BackgroundTransparency = 1, 
        Name = "Drag",
    }, {
        New("ImageLabel", {
            Image = DragIconData and DragIconData[1],
            ImageRectOffset = DragIconData and DragIconData[2] and DragIconData[2].ImageRectPosition,
            ImageRectSize = DragIconData and DragIconData[2] and DragIconData[2].ImageRectSize,
            Size = UDim2.new(0,18,0,18),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5,0,0.5,0),
            AnchorPoint = Vector2.new(0.5,0.5),
            ThemeTag = {
                ImageColor3 = "Icon",
            },
            ImageTransparency = .3,
        })
    })
    local Divider = New("Frame", {
        Size = UDim2.new(0,1,1,0),
        Position = UDim2.new(0,20+16,0.5,0),
        AnchorPoint = Vector2.new(0,0.5),
        BackgroundColor3 = Color3.new(1,1,1),
        BackgroundTransparency = .9,
    })

    local Container = New("Frame", {
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(0.5,0,0,6+44/2),
        AnchorPoint = Vector2.new(0.5,0.5),
        Parent = Window.Parent,
        BackgroundTransparency = 1,
        Active = true,
        Visible = false,
    })


    local UIScale = New("UIScale", {
        Scale = 1,
    })

    local Button = New("Frame", {
        Size = UDim2.new(0,0,0,44),
        AutomaticSize = "X",
        Parent = Container,
        Active = false,
        BackgroundTransparency = .25,
        ZIndex = 99,
        BackgroundColor3 = Color3.new(0,0,0),
    }, {
        UIScale,
	    New("UICorner", {
            CornerRadius = UDim.new(1,0)
        }),
        New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = "Border",
            Color = Color3.new(1,1,1),
            Transparency = 0,
        }, {
            New("UIGradient", {
                Color = ColorSequence.new(Color3.fromHex("40c9ff"), Color3.fromHex("e81cff"))
            })
        }),
        Drag,
        Divider,
        
        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = "Horizontal",
            VerticalAlignment = "Center",
        }),
        
        New("TextButton",{
            AutomaticSize = "XY",
            Active = true,
            BackgroundTransparency = 1, -- .93
            Size = UDim2.new(0,0,0,44-(4*2)),
            --Position = UDim2.new(0,20+16+16+1,0,0),
            BackgroundColor3 = Color3.new(1,1,1),
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(1,-4)
            }),
            Icon,
            New("UIListLayout", {
                Padding = UDim.new(0, Window.UIPadding),
                FillDirection = "Horizontal",
                VerticalAlignment = "Center",
            }),
            TextStack,
            New("UIPadding", {
                PaddingLeft = UDim.new(0,7+4),
                PaddingRight = UDim.new(0,7+4),
            }),
        }),
        New("UIPadding", {
            PaddingLeft = UDim.new(0,4),
            PaddingRight = UDim.new(0,4),
        })
    })
    
    OpenButtonMain.Button = Button
    OpenButtonMain.IconSize = 22
    
    
    
    function OpenButtonMain:SetIcon(newIcon)
        if Icon then
            Icon:Destroy()
        end
        if newIcon then
            Icon = Creator.Image(
                newIcon,
                Window.Title,
                0,
                Window.Folder,
                "OpenButton",
                true,
                Window.IconThemed
            )
            Icon.Size = UDim2.new(0,OpenButtonMain.IconSize,0,OpenButtonMain.IconSize)
            Icon.LayoutOrder = -1
            Icon.Parent = OpenButtonMain.Button.TextButton
        end
    end
    
    if Window.Icon then
        OpenButtonMain:SetIcon(Window.Icon)
    end
    
    
    
    Creator.AddSignal(Button:GetPropertyChangedSignal("AbsoluteSize"), function()
        Container.Size = UDim2.new(
            0, Button.AbsoluteSize.X,
            0, Button.AbsoluteSize.Y
        )
    end)
    
    Creator.AddSignal(Button.TextButton.MouseEnter, function()
        Tween(Button.TextButton, .1, {BackgroundTransparency = .93}):Play()
    end)
    Creator.AddSignal(Button.TextButton.MouseLeave, function()
        Tween(Button.TextButton, .1, {BackgroundTransparency = 1}):Play()
    end)
    
    local DragModule = Creator.Drag(Container)
    
    
    function OpenButtonMain:Visible(v)
        Container.Visible = v
    end

    -- Shows "● 55 fps  ● 130 ms" under the title. Pass nil / false to remove it.
    -- StatusOptions: true or { FPS = true, Ping = true }
    local StatusRow
    function OpenButtonMain:SetStatus(StatusOptions)
        if StatusRow then
            StatusRow:Destroy()
            StatusRow = nil
        end

        local Height = 44
        if StatusOptions then
            local Options = typeof(StatusOptions) == "table" and StatusOptions or {}
            StatusRow = Status.NewRow({
                Parent = TextStack,
                TextSize = 13,
                LayoutOrder = 2,
                ShowFPS = Options.FPS ~= false,
                ShowPing = Options.Ping ~= false,
            })
            Height = 56 -- two text lines need a taller pill
        end

        Button.Size = UDim2.new(0,0,0,Height)
        Button.TextButton.Size = UDim2.new(0,0,0,Height-(4*2))
    end
    
    function OpenButtonMain:SetScale(scale)
        UIScale.Scale = scale
    end
    
    function OpenButtonMain:Edit(OpenButtonConfig)
        local OpenButtonModule = {
            Title = OpenButtonConfig.Title,
            Icon = OpenButtonConfig.Icon,
            Enabled = OpenButtonConfig.Enabled,
            Position = OpenButtonConfig.Position,
            OnlyIcon = OpenButtonConfig.OnlyIcon or false,
            Draggable = OpenButtonConfig.Draggable or nil,
            OnlyMobile = OpenButtonConfig.OnlyMobile,
            CornerRadius = OpenButtonConfig.CornerRadius or UDim.new(1, 0),
            StrokeThickness = OpenButtonConfig.StrokeThickness or 2,
            Scale = OpenButtonConfig.Scale or 1,
            Color = OpenButtonConfig.Color 
                or ColorSequence.new(Color3.fromHex("40c9ff"), Color3.fromHex("e81cff")),
        }

        -- Vexari UI: Style = "Minimal" -> near-black pill with a thin grey outline (no rainbow gradient)
        if OpenButtonConfig.Style == "Minimal" then
            OpenButtonModule.Color = OpenButtonConfig.Color
                or ColorSequence.new(Color3.fromHex("a1a1aa"), Color3.fromHex("52525b"))
            OpenButtonModule.StrokeThickness = OpenButtonConfig.StrokeThickness or 1.5

            Button.BackgroundColor3 = Color3.fromHex("0c0c0f")
            Button.BackgroundTransparency = 0.05
            Title.TextSize = 18
            Title.FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold)
            OpenButtonMain.IconSize = 30
            if Icon then
                Icon.Size = UDim2.new(0,30,0,30)
            end
        end
        
        -- wtf lol
        
        if OpenButtonModule.Enabled == false then
            Window.IsOpenButtonEnabled = false
        end
        
        if OpenButtonModule.OnlyMobile ~= false then
            OpenButtonModule.OnlyMobile = true
        else
            Window.IsPC = false
        end
        
        
        if OpenButtonModule.Draggable == false and Drag and Divider then
            Drag.Visible = OpenButtonModule.Draggable
            Divider.Visible = OpenButtonModule.Draggable
            
            if DragModule then
                DragModule:Set(OpenButtonModule.Draggable)
            end
        end
        
        if OpenButtonModule.Position and Container then
            Container.Position = OpenButtonModule.Position
        end
        
        if OpenButtonModule.OnlyIcon == true and Title then
            Title.Visible = false
            TextStack.Visible = false
            Button.TextButton.UIPadding.PaddingLeft = UDim.new(0,7)
            Button.TextButton.UIPadding.PaddingRight = UDim.new(0,7)
        elseif OpenButtonModule.OnlyIcon == false then
            Title.Visible = true
            TextStack.Visible = true
            Button.TextButton.UIPadding.PaddingLeft = UDim.new(0,7+4)
            Button.TextButton.UIPadding.PaddingRight = UDim.new(0,7+4)
        end
        
        --OpenButtonMain:Visible((not OpenButtonModule.OnlyMobile) or (not Window.IsPC))
        
        --if not OpenButton.Visible then return end
        
        if Title then
            if OpenButtonModule.Title then
                Title.Text = OpenButtonModule.Title
                Creator:ChangeTranslationKey(Title, OpenButtonModule.Title)
            elseif OpenButtonModule.Title == nil then
                --Title.Visible = false
            end
        end
        
        if OpenButtonModule.Icon then
            OpenButtonMain:SetIcon(OpenButtonModule.Icon)
        end

        Button.UIStroke.UIGradient.Color = OpenButtonModule.Color
        if Glow then
            Glow.UIGradient.Color = OpenButtonModule.Color
        end

        Button.UICorner.CornerRadius = OpenButtonModule.CornerRadius
        Button.TextButton.UICorner.CornerRadius = UDim.new(OpenButtonModule.CornerRadius.Scale, OpenButtonModule.CornerRadius.Offset-4)
        Button.UIStroke.Thickness = OpenButtonModule.StrokeThickness
        
        OpenButtonMain:SetScale(OpenButtonModule.Scale)
    end

    return OpenButtonMain
end



return OpenButton