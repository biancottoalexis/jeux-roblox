-- Le boss : un démon géant qui apparaît toutes les 30 minutes.
-- Il poursuit le joueur le plus proche, donne des coups de griffe et lance
-- une onde démoniaque annoncée par un cercle rouge. Tous les joueurs qui
-- l'ont assez frappé reçoivent une récompense quand il meurt.
--
-- Le client lit l'état du boss dans les attributs de workspace :
--   BossAlive, BossHealth, BossMaxHealth, BossNextSpawn (heure serveur)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local CombatService = require(script.Parent.CombatService)
local OrderService = require(script.Parent.OrderService)
local QuestService = require(script.Parent.QuestService)
local Effects = require(script.Parent.Effects)

local BossService = {}

local B = Config.Boss
local AI_TICK = 0.15
local BOSS_COLOR = Color3.fromRGB(200, 20, 40)

local function serverNow(): number
	return workspace:GetServerTimeNow()
end

local function getAlive(character: Model?): (Humanoid?, BasePart?)
	if not character then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil, nil
	end
	return humanoid, root
end

local function playersInRadius(position: Vector3, radius: number): { Humanoid }
	local found = {}
	for _, player in Players:GetPlayers() do
		local humanoid, root = getAlive(player.Character)
		if humanoid and root and (root.Position - position).Magnitude <= radius then
			table.insert(found, humanoid)
		end
	end
	return found
end

local function nearestPlayer(position: Vector3): (BasePart?, number)
	local best, bestDistance = nil, math.huge
	for _, player in Players:GetPlayers() do
		local _, root = getAlive(player.Character)
		if root then
			local distance = (root.Position - position).Magnitude
			local fromSpawn = (root.Position - B.SpawnPosition).Magnitude
			if distance < bestDistance and distance <= B.AggroRange and fromSpawn <= B.LeashRange then
				best, bestDistance = root, distance
			end
		end
	end
	return best, bestDistance
end

local function createModel(): Model?
	local description = Instance.new("HumanoidDescription")
	local dark = Color3.fromRGB(40, 10, 15)
	description.HeadColor = BOSS_COLOR
	description.TorsoColor = dark
	description.LeftArmColor = BOSS_COLOR
	description.RightArmColor = BOSS_COLOR
	description.LeftLegColor = dark
	description.RightLegColor = dark

	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[BossService] Impossible de créer le boss :", model)
		return nil
	end
	pcall(function()
		model:ScaleTo(B.Scale)
	end)

	local torso = model:FindFirstChild("UpperTorso")
	if torso then
		local fire = Instance.new("Fire")
		fire.Color = BOSS_COLOR
		fire.SecondaryColor = Color3.new(0, 0, 0)
		fire.Size = 8
		fire.Parent = torso

		local light = Instance.new("PointLight")
		light.Color = BOSS_COLOR
		light.Range = 30
		light.Brightness = 3
		light.Parent = torso
	end
	return model
end

-- Partage des récompenses entre tous ceux qui ont assez frappé
local function giveRewards(damage: { [Player]: number }, maxHealth: number)
	local top, topDamage = nil, 0
	for player, amount in damage do
		if player.Parent and amount > topDamage then
			top, topDamage = player, amount
		end
	end

	for player, amount in damage do
		if player.Parent and amount >= maxHealth * B.MinDamageShare then
			local spins = if player == top then B.TopDamageSpins else 0
			ProgressionService.AddRewards(player, B.RewardGold, B.RewardXP, spins)
			DataService.Update(player, function(data)
				data.BossKills += 1
			end)
			OrderService.AddMerit(player, Config.Orders.MeritPerBoss)
			QuestService.Progress(player, "Boss", 1)
			Remotes.Notify:FireClient(player, `Récompense du boss : {B.RewardGold} 🪙 et {B.RewardXP} XP !`)
		end
	end

	local topText = if top then ` Plus gros dégâts : {top.DisplayName} ({math.floor(topDamage)})` else ""
	Remotes.Notify:FireAllClients(`☠ Le {B.DisplayName} a été vaincu !{topText}`)
end

-- Fait apparaître le boss et attend qu'il meure ou s'enfuie
local function runBoss()
	local model = createModel()
	if not model then
		return
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart

	local maxHealth = B.BaseHealth + B.HealthPerPlayer * #Players:GetPlayers()
	model.Name = B.DisplayName
	model:SetAttribute("IsBoss", true)
	model:SetAttribute("SuperArmor", true)
	humanoid.DisplayName = B.DisplayName
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.NameDisplayDistance = 200
	humanoid.HealthDisplayDistance = 200
	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	model:PivotTo(CFrame.new(B.SpawnPosition + Vector3.new(0, 4 * B.Scale, 0)))
	model.Parent = workspace
	root:SetNetworkOwner(nil)

	CombatService.TrackHumanoid(humanoid, "Boss")
	humanoid.WalkSpeed = B.WalkSpeed

	workspace:SetAttribute("BossMaxHealth", maxHealth)
	workspace:SetAttribute("BossHealth", maxHealth)
	workspace:SetAttribute("BossAlive", true)
	humanoid.HealthChanged:Connect(function(health)
		workspace:SetAttribute("BossHealth", math.max(0, math.floor(health)))
	end)

	local damage: { [Player]: number } = {}
	local damageConnection = CombatService.DamageDealt:Connect(function(player: Player, target: Humanoid, amount: number)
		if target == humanoid then
			damage[player] = (damage[player] or 0) + amount
		end
	end)

	Remotes.Notify:FireAllClients(`👹 Le {B.DisplayName} est apparu ! Unissez vos forces pour le vaincre !`)

	local died = false
	humanoid.Died:Once(function()
		died = true
	end)

	local enraged = false
	local speed = B.WalkSpeed
	local cooldownMultiplier = 1
	local nextSlash = 0
	local nextWave = os.clock() + 4
	local casting = false
	local deadline = os.clock() + B.Lifetime

	while not died and model.Parent and os.clock() < deadline do
		local t = os.clock()

		if not enraged and humanoid.Health < maxHealth * B.EnrageAt then
			enraged = true
			speed = B.WalkSpeed * B.EnrageSpeedMultiplier
			cooldownMultiplier = B.EnrageCooldownMultiplier
			humanoid.WalkSpeed = speed
			Effects.Burst(root.Position, 20, BOSS_COLOR, 0.8)
			Remotes.Notify:FireAllClients(`🔥 Le {B.DisplayName} est enragé !`)
		end

		local target, distance = nearestPlayer(root.Position)
		if casting then
			-- il prépare son onde : il ne bouge pas
		elseif not target then
			if (root.Position - B.SpawnPosition).Magnitude > 10 then
				humanoid:MoveTo(B.SpawnPosition)
			end
		else
			if distance > B.SlashRange * 0.7 then
				humanoid:MoveTo(target.Position)
			end

			if t >= nextWave and distance <= B.WaveRadius then
				nextWave = t + B.WaveCooldown * cooldownMultiplier
				casting = true
				humanoid.WalkSpeed = 0
				local ground = root.Position - Vector3.new(0, root.Size.Y / 2 + humanoid.HipHeight - 0.5, 0)
				Effects.Warning(ground, B.WaveRadius, B.WaveWarning)
				task.delay(B.WaveWarning, function()
					casting = false
					if died or not model.Parent then
						return
					end
					humanoid.WalkSpeed = speed
					Effects.Burst(root.Position, B.WaveRadius, BOSS_COLOR, 0.6)
					for _, victim in playersInRadius(root.Position, B.WaveRadius) do
						local victimRoot = (victim.Parent :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
						local away = (victimRoot.Position - root.Position) * Vector3.new(1, 0, 1)
						local knockback = if away.Magnitude > 0 then away.Unit * 70 + Vector3.new(0, 35, 0) else nil
						CombatService.DealDamage(nil, model, victim, B.WaveDamage, { Stun = 0.8, Knockback = knockback })
					end
				end)
			elseif t >= nextSlash and distance <= B.SlashRange then
				nextSlash = t + B.SlashCooldown * cooldownMultiplier
				local front = root.Position + root.CFrame.LookVector * (B.SlashRange / 2)
				Effects.Slash(root.CFrame * CFrame.new(0, 0, -B.SlashRange / 2 + 3), BOSS_COLOR)
				for _, victim in playersInRadius(front, B.SlashRange * 0.75) do
					CombatService.DealDamage(nil, model, victim, B.SlashDamage, {
						Stun = 0.5,
						Knockback = root.CFrame.LookVector * 40 + Vector3.new(0, 15, 0),
					})
				end
			end
		end

		task.wait(AI_TICK)
	end

	damageConnection:Disconnect()
	workspace:SetAttribute("BossAlive", false)

	if died then
		giveRewards(damage, maxHealth)
		task.wait(3)
	else
		Remotes.Notify:FireAllClients(`Le {B.DisplayName} s'est enfui...`)
	end
	model:Destroy()
end

function BossService.Init()
	workspace:SetAttribute("BossAlive", false)
end

function BossService.Start()
	task.spawn(function()
		-- En Studio, le premier boss arrive vite pour pouvoir le tester
		local firstDelay = if RunService:IsStudio() then 20 else B.FirstSpawnDelay
		local nextSpawn = serverNow() + firstDelay
		while true do
			workspace:SetAttribute("BossNextSpawn", nextSpawn)

			local announceAt = nextSpawn - 60
			if serverNow() < announceAt then
				task.wait(announceAt - serverNow())
				Remotes.Notify:FireAllClients(`⚠ Le {B.DisplayName} arrive dans 1 minute !`)
			end
			task.wait(math.max(0, nextSpawn - serverNow()))

			nextSpawn = serverNow() + B.Interval
			local ok, err = pcall(runBoss)
			if not ok then
				warn("[BossService] Erreur pendant le combat de boss :", err)
				workspace:SetAttribute("BossAlive", false)
			end
		end
	end)
end

return BossService
