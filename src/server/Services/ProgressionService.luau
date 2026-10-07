-- Récompenses (Yens, XP), montée de niveau et tirage des styles.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Styles = require(Shared.Styles)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local ProgressionService = {}

local SPIN_COOLDOWN = 0.5
local lastSpin: { [Player]: number } = {}
local rng = Random.new()

function ProgressionService.AddRewards(player: Player, yen: number, xp: number)
	if MonetizationService.HasPass(player, "VIP") then
		yen *= 2
	end
	if MonetizationService.HasPass(player, "DoubleXP") then
		xp *= 2
	end

	local levelsGained = 0
	DataService.Update(player, function(data)
		data.Yen += yen
		data.XP += xp
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
		Remotes.Notify:FireClient(player, "Plus de spins ! Achète-en dans la boutique.")
		return
	end

	local styleId = Styles.Roll(rng)
	DataService.Update(player, function(d)
		d.Spins -= 1
		d.Style = styleId
	end)

	local style = Styles.List[styleId]
	Remotes.Notify:FireClient(player, `Tu as obtenu : {style.DisplayName} ({style.Rarity}) !`)
end

function ProgressionService.Init() end

function ProgressionService.Start()
	Remotes.Spin.OnServerEvent:Connect(spin)

	-- Un style gratuit pour les nouveaux joueurs
	DataService.PlayerLoaded:Connect(function(player, data)
		if data.Style == nil then
			DataService.Update(player, function(d)
				d.Style = Styles.Roll(rng)
			end)
		end
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastSpin[player] = nil
	end)
end

return ProgressionService
