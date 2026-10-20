-- Fenêtre « Ordres » : choisir son ordre de chevaliers-mages.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Orders = require(Shared.Orders)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)

local OrderMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

OrderMenu.Frame = nil :: Frame?

local list: ScrollingFrame
local header: TextLabel
local joinButtons: { [string]: TextButton } = {}

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	local current = data.Order and Orders.List[data.Order]
	if current then
		header.Text = `Ton ordre : {current.DisplayName} • {UI.formatNumber(data.Merit)} mérite`
		header.TextColor3 = current.Color
	elseif data.Level < Config.Orders.MinLevel then
		header.Text = `Rejoins un ordre dès le niveau {Config.Orders.MinLevel} !`
		header.TextColor3 = COLORS.Muted
	else
		header.Text = "Choisis ton ordre (gratuit la première fois)"
		header.TextColor3 = COLORS.Text
	end

	for orderId, joinButton in joinButtons do
		local isMine = data.Order == orderId
		if isMine then
			joinButton.Text = "✔ Ton ordre"
		elseif data.Order then
			joinButton.Text = `{UI.formatNumber(Config.Orders.ChangeCost)} 🪙`
		else
			joinButton.Text = "Rejoindre"
		end
		joinButton.AutoButtonColor = not isMine
		joinButton.BackgroundColor3 = if isMine then COLORS.Panel else COLORS.Success
	end
end

local function buildOrder(order: number, orderId: string)
	local def = Orders.List[orderId]
	local frame = make("Frame", {
		Size = UDim2.new(1, -8, 0, 82),
		BackgroundColor3 = COLORS.PanelLight,
		LayoutOrder = order,
		Parent = list,
	}, { UI.corner(8), UI.stroke(def.Color) })
	make("Frame", {
		Size = UDim2.new(0, 6, 1, 0),
		BackgroundColor3 = def.Color,
		Parent = frame,
	}, { UI.corner(4) })

	label({ Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -136, 0, 22), Text = def.DisplayName, TextColor3 = def.Color, Parent = frame })
	label({
		Position = UDim2.fromOffset(16, 32),
		Size = UDim2.new(1, -136, 0, 16),
		Text = `« {def.Motto} »`,
		Font = Enum.Font.GothamMedium,
		TextColor3 = COLORS.Muted,
		Parent = frame,
	})
	label({
		Position = UDim2.fromOffset(16, 54),
		Size = UDim2.new(1, -136, 0, 18),
		Text = `Bonus : {def.BonusText}`,
		TextColor3 = COLORS.Gold,
		Parent = frame,
	})

	local joinButton = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(104, 40),
		Text = "Rejoindre",
		Parent = frame,
	}, COLORS.Success)
	joinButton.Activated:Connect(function()
		local data = State.Data
		if data and data.Order ~= orderId then
			Remotes.Order:FireServer(orderId)
		end
	end)
	joinButtons[orderId] = joinButton
end

function OrderMenu.Build(gui: ScreenGui)
	local frame
	frame, list = UI.panel(gui, "⚔ Ordres de chevaliers", Color3.fromRGB(40, 110, 200))
	OrderMenu.Frame = frame

	header = label({
		Size = UDim2.new(1, -8, 0, 22),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 0,
		Parent = list,
	})
	for index, orderId in Orders.Order do
		buildOrder(index, orderId)
	end
	label({
		Size = UDim2.new(1, -8, 0, 32),
		Text = "Tes kills, quêtes et victoires contre le démon rapportent du mérite à ton ordre. Va voir le 🏆 Classement !",
		TextWrapped = true,
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.Muted,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = 100,
		Parent = list,
	})

	State.DataChanged:Connect(refresh)
	refresh()
end

return OrderMenu
