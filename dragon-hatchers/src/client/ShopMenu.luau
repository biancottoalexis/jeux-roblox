-- Fenêtre « Boutique » : tous les Game Passes rangés par catégorie et les
-- objets (potions, or...). Le pack du débutant est mis en avant en haut.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Monetization"))

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)
local Purchase = require(script.Parent.Purchase)

local ShopMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

ShopMenu.Frame = nil :: Frame?

local list: ScrollingFrame
local tabsFrame: Frame
local tab = "Passes"
local tabButtons: { [string]: TextButton } = {}

-- Ordre d'affichage des passes dans chaque catégorie : du moins cher au plus cher
local function passesOf(category: string): { string }
	local keys = {}
	for key, pass in Monetization.GamePasses do
		if pass.Category == category then
			table.insert(keys, key)
		end
	end
	table.sort(keys, function(a, b)
		return Monetization.GamePasses[a].Price < Monetization.GamePasses[b].Price
	end)
	return keys
end

local function itemRow(order: number, kind: string, key: string)
	local item = Purchase.Item(kind, key)
	local owned = kind == "Pass" and State.HasPass(key)
	local needs = kind == "Pass" and item.Requires and not State.HasPass(item.Requires)
	local sellable = Monetization.IsSellable(item)

	local frame = make("Frame", {
		Size = UDim2.new(1, -8, 0, 66),
		BackgroundColor3 = COLORS.Card,
		LayoutOrder = order,
		Parent = list,
	}, { UI.corner(12), UI.stroke() })
	label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -150, 0, 26), Text = item.Name, Parent = frame })
	label({
		Position = UDim2.fromOffset(12, 34),
		Size = UDim2.new(1, -150, 0, 24),
		Text = item.Description,
		TextWrapped = true,
		TextColor3 = COLORS.Muted,
		Parent = frame,
	})

	local text, color = Purchase.PriceText(kind, key), COLORS.Green
	if owned then
		text, color = "✔ Possédé", COLORS.Gray
	elseif needs then
		text, color = `Nécessite « {Monetization.GamePasses[item.Requires].Name} »`, COLORS.Gray
	elseif not sellable then
		text, color = "Bientôt", COLORS.Gray
	end
	local buy = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(126, 44),
		Text = text,
		Parent = frame,
	}, color)
	if not owned and not needs and sellable then
		buy.Activated:Connect(function()
			Purchase.Prompt(kind, key)
		end)
	end
end

local function starterBanner(order: number)
	local data = State.Data
	local pack = Monetization.Products.StarterPack
	if not data or data.StarterPackBought or not Monetization.IsSellable(pack) then
		return
	end
	local frame = make("Frame", {
		Size = UDim2.new(1, -8, 0, 84),
		BackgroundColor3 = Color3.new(1, 1, 1),
		LayoutOrder = order,
		Parent = list,
	}, { UI.corner(14), UI.stroke(COLORS.Gold, 3), UI.gradient(COLORS.Orange) })
	label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -170, 0, 32), Text = "🎒 PACK DU DÉBUTANT", Parent = frame })
	label({ Position = UDim2.fromOffset(14, 44), Size = UDim2.new(1, -170, 0, 28), Text = pack.Description, TextWrapped = true, Parent = frame })
	local buy = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(140, 52),
		Text = Purchase.PriceText("Product", "StarterPack"),
		Parent = frame,
	}, COLORS.Green)
	buy.Activated:Connect(function()
		Purchase.Prompt("Product", "StarterPack")
	end)
end

local function refresh()
	local frame = ShopMenu.Frame
	if not frame or not frame.Visible then
		return
	end
	for key, tabButton in tabButtons do
		UI.setButtonColor(tabButton, if key == tab then COLORS.Pink else COLORS.Gray)
	end

	for _, child in list:GetChildren() do
		if child ~= tabsFrame and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end

	local order = 10
	starterBanner(order)
	if tab == "Passes" then
		for _, category in Monetization.Categories do
			order += 1
			UI.section(list, order, Monetization.CategoryTitles[category])
			for _, key in passesOf(category) do
				order += 1
				itemRow(order, "Pass", key)
			end
		end
	else
		for _, key in Monetization.ProductOrder do
			local data = State.Data
			if key ~= "StarterPack" or (data and not data.StarterPackBought) then
				order += 1
				itemRow(order, "Product", key)
			end
		end
	end
end

function ShopMenu.Build(gui: ScreenGui)
	local frame
	frame, list = UI.panel(gui, "🛒 Boutique", COLORS.Pink)
	ShopMenu.Frame = frame

	tabsFrame = make("Frame", {
		Size = UDim2.new(1, -8, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = list,
	}, { make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	for index, info in { { Key = "Passes", Title = "⭐ Game Passes" }, { Key = "Items", Title = "🧪 Objets" } } do
		local tabButton = button({
			Size = UDim2.new(0.5, -4, 1, 0),
			Text = info.Title,
			LayoutOrder = index,
			Parent = tabsFrame,
		}, COLORS.Gray)
		tabButton.Activated:Connect(function()
			tab = info.Key
			refresh()
		end)
		tabButtons[info.Key] = tabButton
	end

	-- Ouvrir la boutique directement sur un onglet
	function ShopMenu.Open(which: string?)
		tab = which or tab
		if not frame.Visible then
			UI.togglePanel(frame)
		else
			refresh()
		end
	end

	State.DataChanged:Connect(refresh)
	UI.PanelOpened:Connect(function(opened)
		if opened == frame then
			refresh()
		end
	end)
	Purchase.LoadPrices(refresh)
end

return ShopMenu
