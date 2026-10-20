-- Petits outils pour créer l'interface en code (couleurs, textes, boutons,
-- barres, fenêtres). Utilisés par le HUD et tous les menus.

local UI = {}

UI.COLORS = {
	Panel = Color3.fromRGB(20, 20, 28),
	PanelLight = Color3.fromRGB(38, 38, 52),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(160, 160, 175),
	Health = Color3.fromRGB(230, 60, 70),
	Mana = Color3.fromRGB(70, 120, 255),
	XP = Color3.fromRGB(90, 170, 255),
	Gold = Color3.fromRGB(255, 205, 60),
	Accent = Color3.fromRGB(255, 90, 120),
	Success = Color3.fromRGB(0, 170, 90),
}
local COLORS = UI.COLORS

function UI.make(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end
local make = UI.make

function UI.corner(radius: number?)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

function UI.stroke(color: Color3?)
	return make("UIStroke", { Color = color or Color3.fromRGB(70, 70, 90), Thickness = 1.5 })
end

function UI.label(props: { [string]: any })
	local defaults = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = COLORS.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return make("TextLabel", defaults)
end

function UI.button(props: { [string]: any }, color: Color3)
	local defaults = {
		BackgroundColor3 = color,
		Font = Enum.Font.GothamBlack,
		TextColor3 = COLORS.Text,
		TextScaled = true,
		AutoButtonColor = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return make("TextButton", defaults, { UI.corner(), make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}) })
end

function UI.bar(parent: Instance, position: UDim2, size: UDim2, color: Color3)
	local back = make("Frame", {
		Position = position,
		Size = size,
		BackgroundColor3 = COLORS.PanelLight,
		Parent = parent,
	}, { UI.corner(6) })
	local fill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		Parent = back,
	}, { UI.corner(6) })
	local text = UI.label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = back,
	})
	return fill, text
end

function UI.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (formatted:gsub("^ ", ""))
end

-- Fenêtres : une seule est ouverte à la fois
local panels: { Frame } = {}
local panelOpened = Instance.new("BindableEvent")

-- (frame) : une fenêtre vient de s'ouvrir
UI.PanelOpened = panelOpened.Event

-- Crée une fenêtre au centre de l'écran avec un titre et un bouton X.
-- Renvoie la fenêtre et une zone qui défile pour son contenu.
function UI.panel(parent: Instance, title: string, accent: Color3?): (Frame, ScrollingFrame)
	local frame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.8, 0),
		BackgroundColor3 = COLORS.Panel,
		Visible = false,
		ZIndex = 10,
		Parent = parent,
	}, { UI.corner(12), UI.stroke(accent or COLORS.Accent), make("UISizeConstraint", { MaxSize = Vector2.new(440, 420) }) })

	UI.label({
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -80, 0, 32),
		Text = title,
		Parent = frame,
	})
	local close = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(36, 36),
		Text = "X",
		Parent = frame,
	}, COLORS.Accent)
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 56),
		Size = UDim2.new(1, -32, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

	table.insert(panels, frame)
	return frame, list
end

function UI.togglePanel(frame: Frame)
	local open = not frame.Visible
	for _, other in panels do
		other.Visible = false
	end
	frame.Visible = open
	if open then
		panelOpened:Fire(frame)
	end
end

-- Vide le contenu d'une liste (garde le UIListLayout)
function UI.clear(list: Instance)
	for _, child in list:GetChildren() do
		if not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
end

return UI
