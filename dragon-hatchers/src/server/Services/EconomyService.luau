-- L'or : production des dragons chaque seconde, clics sur « Récolter »,
-- gains hors ligne, potions, déblocage des zones et produits Robux liés à l'or.
--
-- L'or du joueur est envoyé au client avec les attributs "Gold" et
-- "Production" du joueur (ils changent chaque seconde).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Dragons = require(Shared.Dragons)
local Format = require(Shared.Format)
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)
local Zones = require(Shared.Zones)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local OfferService = require(script.Parent.OfferService)

local EconomyService = {}

local E = Config.Economy
local clickWindow: { [Player]: { start: number, count: number } } = {}

function EconomyService.PotionActive(data, kind: string): boolean
	return (data.Potions[kind] or 0) > os.time()
end

-- Tous les bonus d'or du joueur multipliés entre eux
function EconomyService.GoldMultiplier(player: Player, data): number
	local multiplier = 1
	if MonetizationService.HasPass(player, "GoldX2") then
		multiplier *= 2
	end
	if MonetizationService.HasPass(player, "SuperGold") then
		multiplier *= 2
	end
	if MonetizationService.HasPass(player, "VIP") then
		multiplier *= 1.1
	end
	if player.MembershipType == Enum.MembershipType.Premium then
		multiplier *= 1 + E.PremiumBonus
	end
	if EconomyService.PotionActive(data, "Gold") then
		multiplier *= 3
	end
	return multiplier
end

-- Or produit par seconde par tous les dragons, sans les bonus
function EconomyService.RawProduction(data): number
	local total = 0
	for _, dragon in data.Dragons do
		total += Dragons.Production(dragon)
	end
	return total
end

function EconomyService.Production(player: Player): number
	local data = DataService.Get(player)
	if not data then
		return 0
	end
	return EconomyService.RawProduction(data) * EconomyService.GoldMultiplier(player, data)
end

local function updateDisplay(player: Player, data)
	player:SetAttribute("Gold", data.Gold)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		(leaderstats :: any)["🪙 Or"].Value = Format.Short(data.Gold)
	end
end

function EconomyService.AddGold(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	data.Gold += amount
	data.TotalGold += amount
	updateDisplay(player, data)
end

-- Retire de l'or si le joueur en a assez. Renvoie true si c'est fait.
function EconomyService.Spend(player: Player, amount: number): boolean
	local data = DataService.Get(player)
	if not data or data.Gold < amount then
		return false
	end
	data.Gold -= amount
	updateDisplay(player, data)
	return true
end

-- Index de la prochaine zone à débloquer (nil si tout est débloqué)
function EconomyService.NextLockedZone(data): number?
	for index, zone in Zones.List do
		if not data.Zones[zone.Id] then
			return index
		end
	end
	return nil
end

local function grantZone(player: Player, data, index: number)
	local zone = Zones.Get(index)
	data.Zones[zone.Id] = true
	Remotes.Notify:FireClient(player, `{zone.DisplayName} débloqué ! Un nouvel œuf t'attend.`)
	DataService.Refresh(player)
end

-- Débloque une zone avec de l'or (appelé par la barrière de la zone)
function EconomyService.UnlockZone(player: Player, index: number)
	local data = DataService.Get(player)
	local zone = Zones.Get(index)
	if not data or not zone or data.Zones[zone.Id] then
		return
	end
	if EconomyService.NextLockedZone(data) ~= index then
		Remotes.Notify:FireClient(player, "Débloque d'abord la zone d'avant !")
		return
	end
	if not EconomyService.Spend(player, zone.UnlockPrice) then
		Remotes.Notify:FireClient(player, `Il te faut {Format.Short(zone.UnlockPrice)} 🪙 pour débloquer {zone.DisplayName}.`)
		OfferService.Trigger(player, "ZoneClose")
		return
	end
	grantZone(player, data, index)
end

local function addPotion(data, kind: string, minutes: number)
	data.Potions[kind] = math.max(os.time(), data.Potions[kind] or 0) + minutes * 60
end

local function onClick(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local t = os.clock()
	local window = clickWindow[player]
	if not window or t - window.start >= 1 then
		window = { start = t, count = 0 }
		clickWindow[player] = window
	end
	window.count += 1
	if window.count > E.MaxClicksPerSecond then
		return
	end

	local gold = math.max(E.MinClickGold, EconomyService.Production(player) * E.ClickShare)
	if MonetizationService.HasPass(player, "ClickX3") then
		gold *= 3
	end
	data.Stats.Clicks += 1
	EconomyService.AddGold(player, gold)
end

local function giveOfflineEarnings(player: Player, data)
	if data.LastOnline == 0 then
		return
	end
	local O = Config.OfflineEarnings
	local hasPass = MonetizationService.HasPass(player, "OfflinePlus")
	local maxSeconds = (if hasPass then 24 else O.MaxHours) * 3600
	local elapsed = math.min(os.time() - data.LastOnline, maxSeconds)
	if elapsed < O.MinSeconds then
		return
	end
	local rate = if hasPass then 1 else O.Rate
	local amount = EconomyService.RawProduction(data) * EconomyService.GoldMultiplier(player, data) * elapsed * rate
	if amount <= 0 then
		return
	end
	EconomyService.AddGold(player, amount)
	Remotes.OfflineEarnings:FireClient(player, amount, elapsed, hasPass)
end

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local gold = Instance.new("StringValue")
	gold.Name = "🪙 Or"
	gold.Value = "0"
	gold.Parent = leaderstats
	leaderstats.Parent = player
end

local function registerProducts()
	local function goldBag(key: string)
		local product = Monetization.Products[key]
		MonetizationService.OnProduct(key, function(player)
			local amount = math.max(product.MinGold, EconomyService.Production(player) * 60 * product.GoldMinutes)
			EconomyService.AddGold(player, amount)
		end)
	end
	goldBag("GoldSmall")
	goldBag("GoldMedium")
	goldBag("GoldHuge")

	for _, key in { "LuckPotion", "GoldPotion" } do
		local potion = Monetization.Products[key].Potion
		MonetizationService.OnProduct(key, function(_, data)
			addPotion(data, potion.Kind, potion.Minutes)
		end)
	end

	MonetizationService.OnProduct("StarterPack", function(player, data)
		local pack = Monetization.Products.StarterPack
		data.StarterPackBought = true
		addPotion(data, pack.Potion.Kind, pack.Potion.Minutes)
		EconomyService.AddGold(player, pack.Gold)
	end)

	MonetizationService.OnProduct("UnlockZone", function(player, data)
		local index = EconomyService.NextLockedZone(data)
		if index then
			grantZone(player, data, index)
		else
			-- Tout est déjà débloqué : on donne l'équivalent d'un coffre d'or
			EconomyService.AddGold(player, math.max(75000, EconomyService.Production(player) * 3600 * 6))
		end
	end)
end

function EconomyService.Init()
	registerProducts()
end

function EconomyService.Start()
	Remotes.Click.OnServerEvent:Connect(onClick)

	DataService.PlayerLoaded:Connect(function(player, data)
		createLeaderstats(player)
		updateDisplay(player, data)
		giveOfflineEarnings(player, data)
	end)
	Players.PlayerRemoving:Connect(function(player)
		clickWindow[player] = nil
	end)

	-- Production des dragons
	task.spawn(function()
		while true do
			task.wait(Config.Economy.ProductionTick)
			for _, player in Players:GetPlayers() do
				local data = DataService.Get(player)
				if data then
					local production = EconomyService.Production(player)
					player:SetAttribute("Production", production)
					EconomyService.AddGold(player, production * Config.Economy.ProductionTick)

					-- Presque assez pour la zone suivante : on propose de la débloquer
					local next = EconomyService.NextLockedZone(data)
					local zone = next and Zones.Get(next)
					if zone and data.Gold >= zone.UnlockPrice * 0.75 and data.Gold < zone.UnlockPrice then
						OfferService.Trigger(player, "ZoneClose")
					end
				end
			end
		end
	end)
end

return EconomyService
