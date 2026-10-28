-- Les dragons du joueur : éclosion des œufs, fusion, nid, dragons qui suivent
-- le joueur et éclosion automatique.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Dragons = require(Shared.Dragons)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Zones = require(Shared.Zones)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local OfferService = require(script.Parent.OfferService)
local EconomyService = require(script.Parent.EconomyService)

local DragonService = {}

type Dragon = Dragons.Dragon

local rng = Random.new()
local lastHatch: { [Player]: number } = {}
local eggPositions: { [number]: Vector3 } = {}

---------------------------------------------------------------------------
-- Nid
---------------------------------------------------------------------------

function DragonService.Capacity(player: Player, data): number
	local slots = Config.Nest.Upgrades[data.NestLevel].Slots
	if MonetizationService.HasPass(player, "BigNest") then
		slots += 10
	end
	if MonetizationService.HasPass(player, "GiantNest") then
		slots += 25
	end
	return slots
end

local function count(data): number
	local n = 0
	for _ in data.Dragons do
		n += 1
	end
	return n
end

local function nextNestPrice(data): number?
	local upgrade = Config.Nest.Upgrades[data.NestLevel + 1]
	return upgrade and upgrade.Price
end

local function upgradeNest(player: Player)
	local data = DataService.Get(player)
	local price = data and nextNestPrice(data)
	if not data or not price then
		return
	end
	if not EconomyService.Spend(player, price) then
		Remotes.Notify:FireClient(player, `Il te faut {Format.Short(price)} 🪙 pour agrandir ton nid.`)
		return
	end
	DataService.Update(player, function(d)
		d.NestLevel += 1
	end)
	Remotes.Notify:FireClient(player, `Nid agrandi : {DragonService.Capacity(player, data)} places !`)
end

---------------------------------------------------------------------------
-- Dragons qui suivent le joueur
---------------------------------------------------------------------------

local function sortedByProduction(data): { Dragon }
	local list = {}
	for _, dragon in data.Dragons do
		table.insert(list, dragon)
	end
	table.sort(list, function(a, b)
		return Dragons.Production(a) > Dragons.Production(b)
	end)
	return list
end

-- Les meilleurs dragons du joueur sont écrits dans son attribut "Followers" ;
-- chaque client les dessine (moins de travail pour le serveur).
local function updateFollowers(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local amount = if MonetizationService.HasPass(player, "Followers3") then Config.Followers.PassCount else Config.Followers.Count
	local followers = {}
	for i, dragon in sortedByProduction(data) do
		if i > amount then
			break
		end
		table.insert(followers, { S = dragon.S, L = dragon.L, M = dragon.M })
	end
	player:SetAttribute("Followers", HttpService:JSONEncode(followers))
end

---------------------------------------------------------------------------
-- Fusion
---------------------------------------------------------------------------

-- Annonce à tout le serveur les dragons très rares
local function announce(player: Player, dragon: Dragon)
	local mutation = Dragons.Mutations[dragon.M]
	local rarity = Dragons.Rarities[Dragons.Species[dragon.S].Rarity]
	if mutation.Order >= 3 or (rarity.Order >= 4 and mutation.Order >= 2) then
		Remotes.Notify:FireAllClients(`🌟 {player.DisplayName} a obtenu un {Dragons.FullName(dragon)} !`)
	end
end

local function addDragon(data, species: string, level: number, mutation: string): Dragon
	local id = tostring(data.NextDragonId)
	data.NextDragonId += 1
	local dragon = { Id = id, S = species, L = level, M = mutation }
	data.Dragons[id] = dragon
	return dragon
end

-- Fusionne 3 dragons de ce groupe. Renvoie le nouveau dragon (ou nil) et
-- true si sa mutation s'est améliorée.
local function fuseOnce(player: Player, data, key: string): (Dragon?, boolean)
	local group = {}
	for _, dragon in data.Dragons do
		if Dragons.Key(dragon) == key then
			table.insert(group, dragon)
			if #group == Config.Fusion.Required then
				break
			end
		end
	end
	local first = group[1]
	if #group < Config.Fusion.Required or first.L >= Config.Fusion.MaxLevel then
		return nil, false
	end

	for _, dragon in group do
		data.Dragons[dragon.Id] = nil
	end
	local chance = if MonetizationService.HasPass(player, "LuckyFusion")
		then Config.Fusion.LuckyMutationUpgradeChance
		else Config.Fusion.MutationUpgradeChance
	local mutation = first.M
	local better = Dragons.NextMutation(mutation)
	local upgraded = better ~= nil and rng:NextNumber() < chance
	if upgraded then
		mutation = better :: string
	end
	return addDragon(data, first.S, first.L + 1, mutation), upgraded
end

-- Fusionne un groupe (clé) ou tout ce qui peut l'être ("All")
local function fuse(player: Player, which: string, automatic: boolean)
	local data = DataService.Get(player)
	if not data then
		return
	end

	local results = {}
	local upgradedCount = 0
	local function fuseAllOf(key: string): { string }
		local newKeys = {}
		local dragon, upgraded = fuseOnce(player, data, key)
		while dragon do
			table.insert(results, dragon)
			table.insert(newKeys, Dragons.Key(dragon))
			if upgraded then
				upgradedCount += 1
				announce(player, dragon)
			end
			dragon, upgraded = fuseOnce(player, data, key)
		end
		return newKeys
	end

	if which == "All" then
		-- On recommence tant qu'une fusion en permet une autre (niveau suivant)
		local progress = true
		while progress do
			progress = false
			local keys = {}
			for _, dragon in data.Dragons do
				keys[Dragons.Key(dragon)] = true
			end
			for key in keys do
				if #fuseAllOf(key) > 0 then
					progress = true
				end
			end
		end
	else
		-- Un groupe précis, puis les niveaux qu'il vient de créer
		local queue = { which }
		while #queue > 0 do
			for _, key in fuseAllOf(table.remove(queue, 1) :: string) do
				if not table.find(queue, key) then
					table.insert(queue, key)
				end
			end
		end
	end
	if #results == 0 then
		return
	end

	data.Stats.Fused += #results
	DataService.Refresh(player)
	updateFollowers(player)
	Remotes.Fused:FireClient(player, results, automatic, upgradedCount)

	if not automatic and data.Stats.Fused >= Config.Offers.FusionsBeforeAutoFusion then
		OfferService.Trigger(player, "Fusions")
	end
end

---------------------------------------------------------------------------
-- Éclosion
---------------------------------------------------------------------------

function DragonService.Luck(player: Player, data): number
	local luck = 1
	if MonetizationService.HasPass(player, "LuckX2") then
		luck *= 2
	end
	if MonetizationService.HasPass(player, "SuperLuck") then
		luck *= 2
	end
	if EconomyService.PotionActive(data, "Luck") then
		luck *= 3
	end
	return luck
end

local function hatchAmount(player: Player): number
	if MonetizationService.HasPass(player, "OctoHatch") then
		return 8
	elseif MonetizationService.HasPass(player, "TripleHatch") then
		return 3
	end
	return 1
end

-- Ouvre des œufs de la zone. Appelé par l'œuf (ProximityPrompt) ou l'auto-éclosion.
function DragonService.Hatch(player: Player, zoneIndex: number, automatic: boolean?): boolean
	local data = DataService.Get(player)
	local zone = Zones.Get(zoneIndex)
	if not data or not zone then
		return false
	end
	if not data.Zones[zone.Id] then
		Remotes.Notify:FireClient(player, "Débloque d'abord cette zone !")
		return false
	end

	local t = os.clock()
	local cooldown = if MonetizationService.HasPass(player, "FastHatch") then Config.Hatch.FastCooldown else Config.Hatch.Cooldown
	if lastHatch[player] and t - lastHatch[player] < cooldown then
		return false
	end

	local free = DragonService.Capacity(player, data) - count(data)
	if free <= 0 then
		if not automatic then
			Remotes.Notify:FireClient(player, "Ton nid est plein ! Fusionne ou relâche des dragons.")
			OfferService.Trigger(player, "NestFull")
		end
		return false
	end
	local amount = math.min(hatchAmount(player), free, math.floor(data.Gold / zone.EggPrice))
	if amount <= 0 then
		if not automatic then
			Remotes.Notify:FireClient(player, `Il te faut {Format.Short(zone.EggPrice)} 🪙 pour ouvrir cet œuf.`)
			OfferService.Trigger(player, "NoGold")
		end
		return false
	end
	if not EconomyService.Spend(player, amount * zone.EggPrice) then
		return false
	end
	lastHatch[player] = t

	local luck = DragonService.Luck(player, data)
	local legendary = if MonetizationService.HasPass(player, "LegendHunter") then 1.5 else 1
	local hatched = {}
	for _ = 1, amount do
		local rarity = Dragons.RollRarity(rng, legendary)
		local species = Dragons.SpeciesByZone[zoneIndex][rarity]
		local dragon = addDragon(data, species, 1, Dragons.RollMutation(rng, luck))
		table.insert(hatched, dragon)
		announce(player, dragon)
	end
	data.Stats.Hatched += amount

	local fast = MonetizationService.HasPass(player, "FastHatch")
	Remotes.Hatched:FireClient(player, hatched, zoneIndex, fast)
	DataService.Refresh(player)
	updateFollowers(player)

	if MonetizationService.HasPass(player, "AutoFusion") then
		task.delay(if fast then 1 else 2.5, fuse, player, "All", true)
	end
	if data.Stats.Hatched >= Config.Offers.HatchesBeforeMultiHatch then
		OfferService.Trigger(player, "Hatches")
	end
	if count(data) >= DragonService.Capacity(player, data) then
		OfferService.Trigger(player, "NestFull")
	end
	return true
end

-- La carte donne ici la position de l'œuf de chaque zone (pour l'auto-éclosion)
function DragonService.SetEggPosition(zoneIndex: number, position: Vector3)
	eggPositions[zoneIndex] = position
end

local function release(player: Player, id: unknown)
	if typeof(id) ~= "string" then
		return
	end
	local data = DataService.Get(player)
	if not data or not data.Dragons[id] then
		return
	end
	DataService.Update(player, function(d)
		d.Dragons[id] = nil
	end)
	updateFollowers(player)
end

local function autoHatchLoop()
	while true do
		task.wait(Config.Hatch.AutoInterval)
		for _, player in Players:GetPlayers() do
			local data = DataService.Get(player)
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if data and data.AutoHatch and root and MonetizationService.HasPass(player, "AutoHatch") then
				for zoneIndex, position in eggPositions do
					if (root.Position - position).Magnitude <= Config.Hatch.PromptDistance + 4 then
						task.spawn(DragonService.Hatch, player, zoneIndex, true)
						break
					end
				end
			end
		end
	end
end

function DragonService.Init()
	DataService.AddSnapshotField("Capacity", DragonService.Capacity)
	DataService.AddSnapshotField("NestUpgradePrice", function(_, data)
		return nextNestPrice(data)
	end)
	DataService.AddSnapshotField("Luck", DragonService.Luck)
end

function DragonService.Start()
	Remotes.Fuse.OnServerEvent:Connect(function(player, which)
		if typeof(which) == "string" and #which < 80 then
			fuse(player, which, false)
		end
	end)
	Remotes.Release.OnServerEvent:Connect(release)
	Remotes.UpgradeNest.OnServerEvent:Connect(upgradeNest)
	Remotes.AutoHatch.OnServerEvent:Connect(function(player, enabled)
		if typeof(enabled) == "boolean" and MonetizationService.HasPass(player, "AutoHatch") then
			DataService.Update(player, function(d)
				d.AutoHatch = enabled
			end)
		end
	end)

	DataService.PlayerLoaded:Connect(updateFollowers)
	MonetizationService.PassAdded:Connect(function(player, key)
		if key == "Followers3" then
			updateFollowers(player)
		elseif key == "AutoFusion" then
			fuse(player, "All", true)
		end
		DataService.Refresh(player) -- la capacité ou la chance ont pu changer
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastHatch[player] = nil
	end)

	task.spawn(autoHatchLoop)
end

return DragonService
