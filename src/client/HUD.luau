-- Interface du joueur, entièrement créée en code :
-- infos (style, niveau, yens), barre de vie, compétences, spin et boutique.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Styles = require(Shared.Styles)
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)

local HUD = {}

local player = Players.LocalPlayer

local COLORS = {
	Panel = Color3.fromRGB(20, 20, 28),
	PanelLight = Color3.fromRGB(38, 38, 52),
	Text = Color3.fromRGB(240, 240, 245),
	Muted = Color3.fromRGB(160, 160, 175),
	Health = Color3.fromRGB(230, 60, 70),
	XP = Color3.fromRGB(90, 170, 255),
	Gold = Color3.fromRGB(255, 205, 60),
	Accent = Color3.fromRGB(255, 90, 120),
}
local SKILL_KEYS = { "Z", "X", "C", "V" }

local function make(className: string, props: { [string]: any }, children: { Instance }?): any
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

local function corner(radius: number?)
	return make("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function stroke(color: Color3?)
	return make("UIStroke", { Color = color or Color3.fromRGB(70, 70, 90), Thickness = 1.5 })
end

local function label(props: { [string]: any })
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

local function button(props: { [string]: any }, color: Color3)
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
	return make("TextButton", defaults, { corner(), make("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}) })
end

local function bar(parent: Instance, position: UDim2, size: UDim2, color: Color3)
	local back = make("Frame", {
		Position = position,
		Size = size,
		BackgroundColor3 = COLORS.PanelLight,
		Parent = parent,
	}, { corner(6) })
	local fill = make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = color,
		Parent = back,
	}, { corner(6) })
	local text = label({
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 2,
		Parent = back,
	})
	return fill, text
end

local function formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
	return (formatted:gsub("^ ", ""))
end

---------------------------------------------------------------------------

local gui: ScreenGui
local infoStyle, infoLevel, infoYen, infoSpins
local xpFill, xpText
local healthFill, healthText
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

	infoStyle = label({ Size = UDim2.new(1, 0, 0, 26), Text = "Style : ...", Parent = panel })
	infoLevel = label({ Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 20), Text = "Niveau 1", Parent = panel })
	xpFill, xpText = bar(panel, UDim2.fromOffset(0, 54), UDim2.new(1, 0, 0, 14), COLORS.XP)
	infoYen = label({
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(0.6, 0, 0, 20),
		Text = "0 ¥",
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
		Size = UDim2.fromOffset(330, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	})

	healthFill, healthText = bar(holder, UDim2.fromOffset(0, 0), UDim2.new(1, 0, 0, 18), COLORS.Health)

	local row = make("Frame", {
		Position = UDim2.fromOffset(0, 28),
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
	shopFrame = make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(440, 420),
		BackgroundColor3 = COLORS.Panel,
		Visible = false,
		ZIndex = 10,
		Parent = gui,
	}, { corner(12), stroke(COLORS.Accent), make("UISizeConstraint", { MaxSize = Vector2.new(440, 420) }) })

	label({
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -80, 0, 32),
		Text = "🛒 Boutique",
		Parent = shopFrame,
	})
	local close = button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(36, 36),
		Text = "X",
		Parent = shopFrame,
	}, COLORS.Accent)
	close.Activated:Connect(function()
		shopFrame.Visible = false
	end)

	local list = make("ScrollingFrame", {
		Position = UDim2.fromOffset(16, 56),
		Size = UDim2.new(1, -32, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = shopFrame,
	}, { make("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })

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
	local holder = make("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(150, 110),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { make("UIListLayout", { Padding = UDim.new(0, 10) }) })

	local spin = button({ Size = UDim2.fromOffset(150, 48), Text = "🎲 Spin", Parent = holder }, Color3.fromRGB(120, 70, 220))
	spin.Activated:Connect(function()
		Remotes.Spin:FireServer()
	end)

	local shop = button({ Size = UDim2.fromOffset(150, 48), Text = "🛒 Boutique", Parent = holder }, COLORS.Accent)
	shop.Activated:Connect(function()
		shopFrame.Visible = not shopFrame.Visible
	end)
end

local function refreshData()
	local data = State.Data
	if not data then
		return
	end
	local style = data.Style and Styles.List[data.Style]
	if style then
		infoStyle.Text = `{style.DisplayName} • {style.Rarity}`
		infoStyle.TextColor3 = style.Color
	end
	infoLevel.Text = `Niveau {data.Level}`
	xpFill.Size = UDim2.fromScale(math.clamp(data.XP / data.XPNeeded, 0, 1), 1)
	xpText.Text = `{formatNumber(data.XP)} / {formatNumber(data.XPNeeded)} XP`
	infoYen.Text = `{formatNumber(data.Yen)} ¥`
	infoSpins.Text = `🎲 {data.Spins}`

	for slot, ui in skillSlots do
		local skill = style and style.Skills[slot]
		local required = Config.Progression.SkillUnlockLevels[slot]
		if data.Level < required then
			ui.Name.Text = `🔒 Niv {required}`
			ui.Name.TextColor3 = COLORS.Muted
		else
			ui.Name.Text = skill and skill.Name or "-"
			ui.Name.TextColor3 = COLORS.Text
		end
		ui.Stroke.Color = style and style.Color or COLORS.PanelLight
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
