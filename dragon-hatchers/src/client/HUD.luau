-- Interface principale : or et production en haut, boutons des menus à
-- gauche, gros bouton « Récolter » et éclosion automatique à droite,
-- potions actives sous l'or.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)
local Purchase = require(script.Parent.Purchase)
local InventoryMenu = require(script.Parent.InventoryMenu)
local ShopMenu = require(script.Parent.ShopMenu)
local ZoneMenu = require(script.Parent.ZoneMenu)

local HUD = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

local player = Players.LocalPlayer

local gui: ScreenGui
local goldLabel: TextLabel
local productionLabel: TextLabel
local potionsRow: Frame
local dragonsBadge: TextLabel
local autoButton: TextButton
local collectButton: TextButton
local shownGold = 0

local function buildGold()
	local panel = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.fromOffset(280, 62),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	}, { UI.corner(16), UI.stroke(COLORS.Outline, 3), UI.gradient(COLORS.Panel) })
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(48, 48), Text = "🪙", TextXAlignment = Enum.TextXAlignment.Center, Parent = panel })
	goldLabel = label({ Position = UDim2.fromOffset(62, 4), Size = UDim2.new(1, -72, 0, 34), Text = "0", TextColor3 = COLORS.Gold, Parent = panel })
	productionLabel = label({ Position = UDim2.fromOffset(62, 38), Size = UDim2.new(1, -72, 0, 18), Text = "+0 / s", TextColor3 = COLORS.Muted, Parent = panel })

	potionsRow = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 76),
		Size = UDim2.fromOffset(320, 26),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
	}) })
end

local function menuButton(order: number, icon: string, text: string, color: Color3, onClick: () -> ()): TextButton
	local b = button({ Size = UDim2.fromOffset(78, 78), LayoutOrder = order, Parent = nil }, color)
	label({ Size = UDim2.new(1, 0, 0.62, 0), Text = icon, TextXAlignment = Enum.TextXAlignment.Center, Parent = b })
	label({ Position = UDim2.fromScale(0, 0.64), Size = UDim2.new(1, 0, 0.36, 0), Text = text, TextXAlignment = Enum.TextXAlignment.Center, Parent = b })
	b.Activated:Connect(onClick)
	return b
end

local function buildMenuButtons()
	local column = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(78, 3 * 78 + 2 * 10),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })

	local dragons = menuButton(1, "🐉", "Dragons", COLORS.Purple, function()
		UI.togglePanel(InventoryMenu.Frame :: Frame)
	end)
	dragons.Parent = column
	dragonsBadge = label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 6, 0, -8),
		Size = UDim2.fromOffset(52, 20),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = COLORS.Gold,
		ZIndex = 3,
		Parent = dragons,
	})
	menuButton(2, "🛒", "Boutique", COLORS.Pink, function()
		ShopMenu.Open()
	end).Parent = column
	menuButton(3, "🗺", "Zones", COLORS.Blue, function()
		UI.togglePanel(ZoneMenu.Frame :: Frame)
	end).Parent = column
end

-- « +12 » qui s'envole au-dessus du bouton Récolter
local function floatingGain(amount: number)
	local text = label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, math.random(-30, 30), 0, -10),
		Size = UDim2.fromOffset(120, 30),
		Text = `+{Format.Short(amount)}`,
		TextColor3 = COLORS.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 5,
		Parent = collectButton,
	})
	TweenService:Create(text, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = text.Position - UDim2.fromOffset(0, 60),
		TextTransparency = 1,
	}):Play()
	local strokeFade = text:FindFirstChildOfClass("UIStroke")
	if strokeFade then
		TweenService:Create(strokeFade, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	end
	task.delay(0.8, function()
		text:Destroy()
	end)
end

local function buildActions()
	collectButton = button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -110),
		Size = UDim2.fromOffset(118, 118),
		Text = "",
		Parent = gui,
	}, COLORS.Gold)
	local round = collectButton:FindFirstChildOfClass("UICorner") :: UICorner
	round.CornerRadius = UDim.new(1, 0)
	label({ Size = UDim2.fromScale(1, 0.6), Text = "🪙", TextXAlignment = Enum.TextXAlignment.Center, Parent = collectButton })
	label({ Position = UDim2.fromScale(0, 0.6), Size = UDim2.fromScale(1, 0.3), Text = "Récolter", TextXAlignment = Enum.TextXAlignment.Center, Parent = collectButton })
	collectButton.Activated:Connect(function()
		Remotes.Click:FireServer()
		local production = player:GetAttribute("Production") or 0
		local amount = math.max(Config.Economy.MinClickGold, production * Config.Economy.ClickShare)
		if State.HasPass("ClickX3") then
			amount *= 3
		end
		floatingGain(amount)
	end)

	autoButton = button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -24, 1, -238),
		Size = UDim2.fromOffset(118, 40),
		Text = "⚙ Auto 🔒",
		Parent = gui,
	}, COLORS.Gray)
	autoButton.Activated:Connect(function()
		local data = State.Data
		if not State.HasPass("AutoHatch") then
			Purchase.Prompt("Pass", "AutoHatch")
		elseif data then
			Remotes.AutoHatch:FireServer(not data.AutoHatch)
		end
	end)
end

local function potionChip(text: string, color: Color3)
	local chip = make("Frame", {
		Size = UDim2.fromOffset(150, 26),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = potionsRow,
	}, { UI.corner(10), UI.stroke(), UI.gradient(color) })
	label({ Size = UDim2.fromScale(1, 1), Text = text, TextXAlignment = Enum.TextXAlignment.Center, Parent = chip, ZIndex = 2 })
end

local function refreshPotions()
	UI.clear(potionsRow)
	local data = State.Data
	if not data then
		return
	end
	local now = workspace:GetServerTimeNow()
	local luck = (data.Potions.Luck or 0) - now
	local gold = (data.Potions.Gold or 0) - now
	if luck > 0 then
		potionChip(`🍀 Chance x3 • {Format.Duration(luck)}`, COLORS.Green)
	end
	if gold > 0 then
		potionChip(`🪙 Or x3 • {Format.Duration(gold)}`, COLORS.Orange)
	end
end

local function refreshData()
	local data = State.Data
	if not data then
		return
	end
	local fusable = false
	for _, group in InventoryMenu.Groups(data.Dragons) do
		if InventoryMenu.CanFuse(group) then
			fusable = true
			break
		end
	end
	dragonsBadge.Text = `{#data.Dragons}/{data.Capacity}{if fusable then " 🔁" else ""}`
	dragonsBadge.TextColor3 = if #data.Dragons >= data.Capacity then COLORS.Red else COLORS.Gold

	if not State.HasPass("AutoHatch") then
		autoButton.Text = "⚙ Auto 🔒"
		UI.setButtonColor(autoButton, COLORS.Gray)
	elseif data.AutoHatch then
		autoButton.Text = "⚙ Auto : OUI"
		UI.setButtonColor(autoButton, COLORS.Green)
	else
		autoButton.Text = "⚙ Auto : NON"
		UI.setButtonColor(autoButton, COLORS.Red)
	end
	refreshPotions()
end

function HUD.Start()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	gui = make("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	buildGold()
	buildMenuButtons()
	buildActions()
	InventoryMenu.Build(gui)
	ShopMenu.Build(gui)
	ZoneMenu.Build(gui)

	State.DataChanged:Connect(refreshData)
	refreshData()

	-- Le compteur d'or monte en douceur au lieu de sauter
	RunService.RenderStepped:Connect(function(dt)
		local target = State.Gold()
		if math.abs(target - shownGold) < 1 or target < shownGold then
			shownGold = target
		else
			shownGold += (target - shownGold) * math.min(1, dt * 8)
		end
		goldLabel.Text = Format.Short(shownGold)
		productionLabel.Text = `+{Format.Short(player:GetAttribute("Production") or 0)} / s`
	end)

	-- Les minuteurs des potions
	task.spawn(function()
		while true do
			task.wait(1)
			refreshPotions()
		end
	end)
end

return HUD
