-- Interface du joueur, entièrement créée en code :
-- infos (grimoire, niveau, or), vie, mana, sorts, tirage de grimoire, boutique
-- et boutons des menus (quêtes, ordres, classement).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grimoires = require(Shared.Grimoires)
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)
local QuestMenu = require(script.Parent.QuestMenu)
local OrderMenu = require(script.Parent.OrderMenu)
local LeaderboardMenu = require(script.Parent.LeaderboardMenu)
local BossBar = require(script.Parent.BossBar)

local HUD = {}

local player = Players.LocalPlayer

local COLORS = UI.COLORS
local make, corner, stroke, label, button, bar, formatNumber =
	UI.make, UI.corner, UI.stroke, UI.label, UI.button, UI.bar, UI.formatNumber
local SKILL_KEYS = { "Z", "X", "C", "V" }

---------------------------------------------------------------------------

local gui: ScreenGui
local infoGrimoire, infoLevel, infoGold, infoSpins
local xpFill, xpText
local healthFill, healthText
local manaFill, manaText
local skillSlots = {}
local notifyLabel
local shopFrame

local function buildInfoPanel()
	local panel = make("Frame", {
		Position = UDim2.fromOffset(12, 70),
		Size = UDim2.fromOffset(250, 128),
		BackgroundColor3 = COLORS.Panel,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { corner(10), stroke(), make("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}) })

	infoGrimoire = label({ Size = UDim2.new(1, 0, 0, 26), Text = "Grimoire : ...", Parent = panel })
	infoLevel = label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 20), Text = "Niveau 1", Parent = panel })
	xpFill, xpText = bar(panel, UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 14), COLORS.XP)
	infoGold = label({
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(0.6, 0, 0, 20),
		Text = "0 🪙",
		TextColor3 = COLORS.Gold,
		Parent = panel,
	})
	infoSpins = label({
		Position = UDim2.new(0.6, 0, 0, 74),
		Size = UDim2.new(0.4, 0, 0, 20),
		Text = "🎲 0",
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = panel,
	})
end

local function buildHealthAndSkills()
	local holder = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(330, 132),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	healthFill, healthText = bar(holder, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18), COLORS.Health)
	manaFill, manaText = bar(holder, UDim2.fromOffset(0, 22), UDim2.new(1, 0, 0, 14), COLORS.Mana)

	local row = make("Frame", {
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 0, 78),
		BackgroundTransparency = 1,
		Parent = holder,
	}, { make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
	}) })

	for slot = 1, 4 do
		local frame = make("Frame", {
			Size = UDim2.fromOffset(76, 78),
			BackgroundColor3 = COLORS.Panel,
			BackgroundTransparency = 0.1,
			ClipsDescendants = true,
			LayoutOrder = slot,
			Parent = row,
		}, { corner(10) })
		local frameStroke = stroke()
		frameStroke.Parent = frame

		label({
			Position = UDim2.fromOffset(6, 4),
			Size = UDim2.fromOffset(20, 18),
			Text = SKILL_KEYS[slot],
			TextColor3 = COLORS.Gold,
			Parent = frame,
		})
		local name = label({
			Position = UDim2.fromOffset(4, 26),
			Size = UDim2.new(1, -8, 0, 44),
			Text = "-",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextWrapped = true,
			Font = Enum.Font.Gotham,
			Parent = frame,
		})
		local overlay = make("Frame", {
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.fromScale(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.35,
			ZIndex = 3,
			Parent = frame,
		})
		local timer = label({
			Size = UDim2.fromScale(1, 1),
			Text = "",
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 4,
			Parent = frame,
		})
		skillSlots[slot] = { Name = name, Overlay = overlay, Timer = timer, Stroke = frameStroke }
	end
end

local function notify(message: string)
	notifyLabel.Text = message
	notifyLabel.TextTransparency = 0
	notifyLabel.TextStrokeTransparency = 0.3
	local tween = TweenService:Create(notifyLabel, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 2.5), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
end

local function shopItem(parent: Instance, order: number, title: string, description: string, id: number, isPass: boolean)
	local item = make("Frame", {
		Size = UDim2.new(1, 0, 0, 64),
		BackgroundColor3 = COLORS.PanelLight,
		LayoutOrder = order,
		Parent = parent,
	}, { corner(8) })
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -130, 0, 24), Text = title, Parent = item })
	label({
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -130, 0, 18),
		Text = description,
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.Muted,
		Parent = item,
	})

	local configured = id ~= 0
	local buy = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(100, 40),
		Text = if configured then "Acheter" else "Bientôt",
		AutoButtonColor = configured,
		Parent = item,
	}, if configured then Color3.fromRGB(0, 170, 90) else COLORS.Panel)

	if not configured then
		return
	end

	-- Affiche le vrai prix défini sur Roblox
	task.spawn(function()
		local infoType = if isPass then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(id, infoType)
		end)
		if ok and info and info.PriceInRobux then
			buy.Text = `R$ {info.PriceInRobux}`
		end
	end)

	buy.Activated:Connect(function()
		if isPass then
			MarketplaceService:PromptGamePassPurchase(player, id)
		else
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
end

local function buildShop()
	local list
	shopFrame, list = UI.panel(gui, "🛒 Boutique")

	local order = 0
	for _, key in Monetization.GamePassOrder do
		local pass = Monetization.GamePasses[key]
		order += 1
		shopItem(list, order, `⭐ {pass.Name}`, pass.Description, pass.Id, true)
	end
	for _, key in Monetization.ProductOrder do
		local product = Monetization.Products[key]
		order += 1
		shopItem(list, order, product.Name, product.Description, product.Id, false)
	end
end

local function buildSideButtons()
	-- 2 colonnes de boutons, à gauche sous le panneau d'infos
	local holder = make("Frame", {
		Position = UDim2.fromOffset(12, 208),
		Size = UDim2.fromOffset(236, 136),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { make("UIGridLayout", {
		CellSize = UDim2.fromOffset(114, 40),
		CellPadding = UDim2.fromOffset(8, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })

	local function sideButton(order: number, text: string, color: Color3, onClick: () -> ())
		local b = button({ Text = text, LayoutOrder = order, Parent = holder }, color)
		b.Activated:Connect(onClick)
		return b
	end

	sideButton(1, "📖 Grimoire", Color3.fromRGB(120, 70, 220), function()
		Remotes.Spin:FireServer()
	end)
	sideButton(2, "🛒 Boutique", COLORS.Accent, function()
		UI.togglePanel(shopFrame)
	end)
	local questButton = sideButton(3, "📜 Quêtes", Color3.fromRGB(200, 130, 30), function()
		UI.togglePanel(QuestMenu.Frame)
	end)
	sideButton(4, "⚔ Ordres", Color3.fromRGB(40, 110, 200), function()
		UI.togglePanel(OrderMenu.Frame)
	end)
	sideButton(5, "🏆 Classement", Color3.fromRGB(40, 150, 110), function()
		UI.togglePanel(LeaderboardMenu.Frame)
	end)

	QuestMenu.Build(gui, questButton)
	OrderMenu.Build(gui)
	LeaderboardMenu.Build(gui)
end

local function refreshData()
	local data = State.Data
	if not data then
		return
	end
	local grimoire = data.Grimoire and Grimoires.List[data.Grimoire]
	if grimoire then
		infoGrimoire.Text = `{grimoire.DisplayName} • {grimoire.Rarity}`
		infoGrimoire.TextColor3 = Grimoires.Rarities[grimoire.Rarity]
	end
	infoLevel.Text = `Niveau {data.Level}`
	xpFill.Size = UDim2.fromScale(math.clamp(data.XP / data.XPNeeded, 0, 1), 1)
	xpText.Text = `{formatNumber(data.XP)} / {formatNumber(data.XPNeeded)} XP`
	infoGold.Text = `{formatNumber(data.Gold)} 🪙`
	infoSpins.Text = `🎲 {data.Spins}`

	for slot, ui in skillSlots do
		local skill = grimoire and grimoire.Skills[slot]
		local required = Config.Progression.SkillUnlockLevels[slot]
		if data.Level < required then
			ui.Name.Text = `🔒 Niv {required}`
			ui.Name.TextColor3 = COLORS.Muted
		else
			ui.Name.Text = if skill then `{skill.Name}\n{skill.ManaCost} mana` else "-"
			ui.Name.TextColor3 = COLORS.Text
		end
		ui.Stroke.Color = grimoire and grimoire.Color or COLORS.PanelLight
	end
end

local function trackHealth(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local function update()
		healthFill.Size = UDim2.fromScale(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 1)
		healthText.Text = `{math.ceil(humanoid.Health)} / {humanoid.MaxHealth}`
	end
	humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()

	local function updateMana()
		local mana = character:GetAttribute("Mana") or 0
		local maxMana = character:GetAttribute("MaxMana") or 100
		manaFill.Size = UDim2.fromScale(math.clamp(mana / maxMana, 0, 1), 1)
		manaText.Text = `{math.floor(mana)} / {maxMana} mana`
	end
	character:GetAttributeChangedSignal("Mana"):Connect(updateMana)
	character:GetAttributeChangedSignal("MaxMana"):Connect(updateMana)
	updateMana()
end

local function updateCooldowns()
	local now = os.clock()
	for slot, ui in skillSlots do
		local cooldown = State.Cooldowns[`Skill{slot}`]
		local remaining = cooldown and cooldown.Ends - now or 0
		if remaining > 0 then
			ui.Overlay.Size = UDim2.fromScale(1, remaining / cooldown.Duration)
			ui.Timer.Text = string.format("%.1f", remaining)
		else
			ui.Overlay.Size = UDim2.fromScale(1, 0)
			ui.Timer.Text = ""
		end
	end
end

function HUD.Start()
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)

	gui = make("ScreenGui", {
		Name = "HUD",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = player:WaitForChild("PlayerGui"),
	})

	buildInfoPanel()
	buildHealthAndSkills()
	buildShop()
	buildSideButtons()
	BossBar.Build(gui)

	notifyLabel = label({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 70),
		Size = UDim2.new(0.6, 0, 0, 36),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = COLORS.Gold,
		TextTransparency = 1,
		TextStrokeTransparency = 1,
		Parent = gui,
	})

	State.DataChanged:Connect(refreshData)
	refreshData()
	Remotes.Notify.OnClientEvent:Connect(notify)

	player.CharacterAdded:Connect(trackHealth)
	if player.Character then
		task.spawn(trackHealth, player.Character)
	end

	RunService.RenderStepped:Connect(updateCooldowns)
end

return HUD
