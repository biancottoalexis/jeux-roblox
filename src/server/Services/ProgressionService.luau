-- Récompenses (or, XP), montée de niveau et tirage des grimoires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Grimoires = require(Shared.Grimoires)
local Orders = require(Shared.Orders)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local ProgressionService = {}

local SPIN_COOLDOWN = 0.5
local lastSpin: { [Player]: number } = {}
local rng = Random.new()

-- Donne de l'or, de l'XP et éventuellement des tirages (bonus VIP, XP x2 et
-- bonus d'ordre compris)
function ProgressionService.AddRewards(player: Player, gold: number, xp: number, spins: number?)
	local current = DataService.Get(player)
	local orderId = current and current.Order
	gold = math.floor(gold * (1 + Orders.BonusFor(orderId, "Gold")))
	xp = math.floor(xp * (1 + Orders.BonusFor(orderId, "XP")))
	if MonetizationService.HasPass(player, "VIP") then
		gold *= 2
	end
	if MonetizationService.HasPass(player, "DoubleXP") then
		xp *= 2
	end

	local levelsGained = 0
	DataService.Update(player, function(data)
		data.Gold += gold
		data.XP += xp
		data.Spins += spins or 0
		while data.Level < Config.Progression.MaxLevel and data.XP >= Config.XPForLevel(data.Level) do
			data.XP -= Config.XPForLevel(data.Level)
			data.Level += 1
			levelsGained += 1
		end
	end)

	if levelsGained > 0 then
		local data = DataService.Get(player)
		Remotes.Notify:FireClient(player, `Niveau {data.Level} atteint !`)
	end
end

function ProgressionService.UnlockedSkillCount(level: number): number
	local count = 0
	for _, required in Config.Progression.SkillUnlockLevels do
		if level >= required then
			count += 1
		end
	end
	return count
end

local function spin(player: Player)
	local now = os.clock()
	if lastSpin[player] and now - lastSpin[player] < SPIN_COOLDOWN then
		return
	end
	lastSpin[player] = now

	local data = DataService.Get(player)
	if not data then
		return
	end
	if data.Spins <= 0 then
		Remotes.Notify:FireClient(player, "Plus de tirages ! Achètes-en dans la boutique.")
		return
	end

	local grimoireId = Grimoires.Roll(rng)
	DataService.Update(player, function(d)
		d.Spins -= 1
		d.Grimoire = grimoireId
	end)

	local grimoire = Grimoires.List[grimoireId]
	Remotes.Notify:FireClient(player, `Ton grimoire s'ouvre : {grimoire.DisplayName} ({grimoire.Rarity}) !`)
end

function ProgressionService.Init() end

function ProgressionService.Start()
	Remotes.Spin.OnServerEvent:Connect(spin)

	-- Un grimoire gratuit pour les nouveaux joueurs
	DataService.PlayerLoaded:Connect(function(player, data)
		if data.Grimoire == nil then
			DataService.Update(player, function(d)
				d.Grimoire = Grimoires.Roll(rng)
			end)
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastSpin[player] = nil
	end)
end

return ProgressionService
