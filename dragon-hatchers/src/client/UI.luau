-- Petits outils pour créer l'interface en code, avec un style « simulateur »
-- (police arrondie, contours épais, dégradés, boutons qui rebondissent).
-- Utilisés par le HUD et tous les menus.

local TweenService = game:GetService("TweenService")

local UI = {}

UI.FONT = Enum.Font.FredokaOne

UI.COLORS = {
	Panel = Color3.fromRGB(32, 30, 58),
	PanelLight = Color3.fromRGB(52, 48, 92),
	Card = Color3.fromRGB(64, 58, 112),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(180, 175, 215),
	Outline = Color3.fromRGB(15, 12, 35),
	Gold = Color3.fromRGB(255, 205, 50),
	Green = Color3.fromRGB(70, 210, 90),
	Blue = Color3.fromRGB(60, 150, 255),
	Purple = Color3.fromRGB(150, 80, 255),
	Pink = Color3.fromRGB(255, 80, 150),
	Orange = Color3.fromRGB(255, 140, 40),
	Red = Color3.fromRGB(240, 60, 70),
	Gray = Color3.fromRGB(95, 90, 125),
}
local COLORS = UI.COLORS

function UI.make(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end
local make = UI.make

function UI.corner(radius: number?)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function UI.stroke(color: Color3?, thickness: number?)
	return make("UIStroke", {
		Color = color or COLORS.Outline,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- Dégradé vertical : la couleur en haut, plus foncée en bas
function UI.gradient(color: Color3)
	local h, s, v = color:ToHSV()
	return make("UIGradient", {
		Color = ColorSequence.new(color, Color3.fromHSV(h, s, v * 0.72)),
		Rotation = 90,
	})
end

function UI.padding(pixels: number)
	local p = UDim.new(0, pixels)
	return make("UIPadding", { PaddingTop = p, PaddingBottom = p, PaddingLeft = p, PaddingRight = p })
end

-- Texte avec contour (style des simulateurs)
function UI.label(props: { [string]: any })
	local defaults = {
		BackgroundTransparency = 1,
		Font = UI.FONT,
		TextColor3 = COLORS.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		TextStrokeTransparency = 1,
	}
	for key, value in props do
		defaults[key] = value
	end
	local label = make("TextLabel", defaults)
	make("UIStroke", { Color = COLORS.Outline, Thickness = 2, Parent = label })
	return label
end

-- Petit rebond quand on appuie sur un bouton
function UI.bounce(guiObject: GuiObject)
	local scale = guiObject:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = guiObject })
	scale.Scale = 0.88
	TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function UI.button(props: { [string]: any }, color: Color3)
	local defaults = {
		BackgroundColor3 = Color3.new(1, 1, 1),
		Font = UI.FONT,
		TextColor3 = COLORS.Text,
		TextScaled = true,
		AutoButtonColor = false,
		Text = "",
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = make("TextButton", defaults, {
		UI.corner(),
		UI.stroke(),
		UI.gradient(color),
		make("UIPadding", {
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
	})
	make("UIStroke", { Color = COLORS.Outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = button })
	button.Activated:Connect(function()
		UI.bounce(button)
	end)
	return button
end

-- Change la couleur d'un bouton créé avec UI.button
function UI.setButtonColor(button: GuiObject, color: Color3)
	local old = button:FindFirstChildOfClass("UIGradient")
	if old then
		old:Destroy()
	end
	UI.gradient(color).Parent = button
end

function UI.bar(parent: Instance, position: UDim2, size: UDim2, color: Color3)
	local back = make("Frame", {
		Position = position,
		Size = size,
		BackgroundColor3 = COLORS.Outline,
		Parent = parent,
	}, { UI.corner(8) })
	local fill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = back,
	}, { UI.corner(8), UI.gradient(color) })
	local text = UI.label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = back,
	})
	return fill, text
end

-- Fenêtres : une seule est ouverte à la fois
local panels: { Frame } = {}
local panelOpened = Instance.new("BindableEvent")

-- (frame) : une fenêtre vient de s'ouvrir
UI.PanelOpened = panelOpened.Event

-- Crée une fenêtre au centre de l'écran avec un titre et un bouton X.
-- Renvoie la fenêtre et une zone qui défile pour son contenu.
function UI.panel(parent: Instance, title: string, accent: Color3, maxSize: Vector2?): (Frame, ScrollingFrame)
	local frame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.92, 0.82),
		BackgroundColor3 = COLORS.Panel,
		Visible = false,
		ZIndex = 10,
		Parent = parent,
	}, {
		UI.corner(18),
		UI.stroke(COLORS.Outline, 4),
		make("UISizeConstraint", { MaxSize = maxSize or Vector2.new(620, 460) }),
	})

	-- Bandeau du titre
	local header = make("Frame", {
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = frame,
	}, { UI.corner(18), UI.gradient(accent) })
	UI.label({
		Position = UDim2.fromOffset(18, 8),
		Size = UDim2.new(1, -80, 0, 36),
		Text = title,
		Parent = header,
	})
	local close = UI.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(40, 36),
		Text = "X",
		Parent = header,
	}, COLORS.Red)
	close.Activated:Connect(function()
		frame.Visible = false
	end)

	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = COLORS.Muted,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = frame,
	}, { make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

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
		-- Petite apparition qui rebondit
		local scale = frame:FindFirstChildOfClass("UIScale") or make("UIScale", { Parent = frame })
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		panelOpened:Fire(frame)
	end
end

function UI.closePanels()
	for _, frame in panels do
		frame.Visible = false
	end
end

-- Vide un conteneur (garde les UIListLayout / UIGridLayout / UIPadding)
function UI.clear(container: Instance)
	for _, child in container:GetChildren() do
		if not child:IsA("UIGridStyleLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

-- Titre de section dans une liste
function UI.section(parent: Instance, order: number, text: string)
	return UI.label({
		Size = UDim2.new(1, -8, 0, 28),
		Text = text,
		LayoutOrder = order,
		Parent = parent,
	})
end

return UI
