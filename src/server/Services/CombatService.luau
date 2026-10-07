-- Le système de combat. Tout est vérifié côté serveur pour éviter la triche :
-- le client demande une action, le serveur décide si elle est permise.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Styles = require(Shared.Styles)
local Remotes = require(Shared.Remotes)
local Movement = require(Shared.Movement)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local Effects = require(script.Parent.Effects)

local CombatService = {}

local C = Config.Combat

type CombatState = {
	combo: number,
	lastM1: number,
	nextM1: number,
	cooldowns: { [string]: number },
}

-- État de combat par personnage (clés faibles : nettoyé quand le perso disparaît)
local states: { [Model]: CombatState } = setmetatable({}, { __mode = "k" }) :: any

local function getState(character: Model): CombatState
	local state = states[character]
	if not state then
		state = { combo = 0, lastM1 = 0, nextM1 = 0, cooldowns = {} }
		states[character] = state
	end
	return state
end

local function now(): number
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

local function isStunned(character: Model): boolean
	return (character:GetAttribute("StunnedUntil") or 0) > now()
end

local function updateSpeed(character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	if isStunned(character) then
		humanoid.WalkSpeed = C.StunWalkSpeed
	elseif character:GetAttribute("Blocking") then
		humanoid.WalkSpeed = C.BlockWalkSpeed
	else
		humanoid.WalkSpeed = C.DefaultWalkSpeed
	end
end

local function applyStun(character: Model, duration: number)
	local untilTime = math.max(character:GetAttribute("StunnedUntil") or 0, now() + duration)
	character:SetAttribute("StunnedUntil", untilTime)
	updateSpeed(character)
	task.delay(duration + 0.05, function()
		if character.Parent then
			updateSpeed(character)
		end
	end)
end

local function applyKnockback(character: Model, velocity: Vector3)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		-- Le joueur contrôle la physique de son personnage : c'est son client qui bouge
		Remotes.Knockback:FireClient(player, velocity, 0.2)
	else
		Movement.ApplyVelocity(root, velocity, 0.2)
	end
end

local function overlapParams(exclude: { Instance }): OverlapParams
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	return params
end

local function humanoidsFromParts(parts: { BasePart }): { Humanoid }
	local found = {}
	local seen = {}
	for _, part in parts do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not seen[humanoid] then
			seen[humanoid] = true
			table.insert(found, humanoid)
		end
	end
	return found
end

local function hitBox(cframe: CFrame, size: Vector3, attacker: Model): { Humanoid }
	return humanoidsFromParts(workspace:GetPartBoundsInBox(cframe, size, overlapParams({ attacker })))
end

local function hitRadius(position: Vector3, radius: number, attacker: Model): { Humanoid }
	return humanoidsFromParts(workspace:GetPartBoundsInRadius(position, radius, overlapParams({ attacker })))
end

type DamageOptions = {
	Stun: number?,
	Knockback: Vector3?,
}

function CombatService.DealDamage(attacker: Player?, attackerCharacter: Model, target: Humanoid, amount: number, options: DamageOptions?)
	local opts = options or {}
	local targetCharacter = target.Parent :: Model
	local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerRoot = attackerCharacter:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot or not attackerRoot then
		return
	end

	-- La garde ne marche que si la cible fait face à l'attaquant
	local blocked = false
	if targetCharacter:GetAttribute("Blocking") then
		local toAttacker = (attackerRoot.Position - targetRoot.Position) * Vector3.new(1, 0, 1)
		if toAttacker.Magnitude > 0 and targetRoot.CFrame.LookVector:Dot(toAttacker.Unit) > C.BlockAngle then
			blocked = true
			amount *= 1 - C.BlockDamageReduction
		end
	end

	if attacker then
		targetCharacter:SetAttribute("LastAttackerId", attacker.UserId)
		targetCharacter:SetAttribute("LastHitAt", now())
	end

	target:TakeDamage(amount)
	Effects.DamageNumber(targetRoot, amount, blocked)

	if not blocked then
		if opts.Stun then
			applyStun(targetCharacter, opts.Stun)
		end
		if opts.Knockback then
			applyKnockback(targetCharacter, opts.Knockback)
		end
	end
end

-- Attribue la récompense au dernier joueur qui a frappé
local function onDied(humanoid: Humanoid, isDummy: boolean)
	local character = humanoid.Parent :: Model
	local killerId = character:GetAttribute("LastAttackerId")
	local hitAt = character:GetAttribute("LastHitAt") or 0
	local victim = Players:GetPlayerFromCharacter(character)

	if victim then
		DataService.Update(victim, function(data)
			data.Deaths += 1
		end)
	end

	if not killerId or now() - hitAt > C.LastAttackerWindow then
		return
	end
	local killer = Players:GetPlayerByUserId(killerId)
	if not killer or killer == victim then
		return
	end

	local P = Config.Progression
	if isDummy then
		ProgressionService.AddRewards(killer, P.DummyYen, P.DummyXP)
	else
		DataService.Update(killer, function(data)
			data.Kills += 1
		end)
		ProgressionService.AddRewards(killer, P.KillYen, P.KillXP)
		Remotes.Notify:FireClient(killer, `Tu as vaincu {victim and victim.DisplayName or "un ennemi"} !`)
	end
end

function CombatService.TrackHumanoid(humanoid: Humanoid, isDummy: boolean)
	local character = humanoid.Parent :: Model
	character:SetAttribute("StunnedUntil", 0)
	character:SetAttribute("Blocking", false)
	humanoid.WalkSpeed = C.DefaultWalkSpeed
	humanoid.Died:Once(function()
		onDied(humanoid, isDummy)
	end)
end

---------------------------------------------------------------------------
-- Compétences
---------------------------------------------------------------------------

local SkillKinds = {}

function SkillKinds.Projectile(player: Player, character: Model, root: BasePart, skill, color: Color3)
	local direction = root.CFrame.LookVector
	local orb = Effects.Orb(root.Position + direction * 3, skill.Radius, color)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character, workspace:FindFirstChild("Effects") :: Instance }

	local traveled = 0
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		local step = skill.Speed * dt
		local wall = workspace:Raycast(orb.Position, direction * step, rayParams)
		traveled += step
		orb.Position += direction * step

		local hits = hitRadius(orb.Position, skill.Radius, character)
		if #hits == 0 and not wall and traveled < skill.Range then
			return
		end

		connection:Disconnect()
		local position = orb.Position
		orb:Destroy()
		Effects.Burst(position, skill.Radius * 1.5, color)
		for _, humanoid in hitRadius(position, skill.Radius * 1.5, character) do
			CombatService.DealDamage(player, character, humanoid, skill.Damage, {
				Stun = skill.Stun,
				Knockback = direction * 30 + Vector3.new(0, 15, 0),
			})
		end
	end)
end

function SkillKinds.Nova(player: Player, character: Model, root: BasePart, skill, color: Color3)
	Effects.Burst(root.Position, skill.Radius, color, 0.5)
	for _, humanoid in hitRadius(root.Position, skill.Radius, character) do
		local targetRoot = (humanoid.Parent :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
		local knockback = nil
		if skill.Knockback and targetRoot then
			local away = (targetRoot.Position - root.Position) * Vector3.new(1, 0, 1)
			if away.Magnitude > 0 then
				knockback = away.Unit * skill.Knockback + Vector3.new(0, 25, 0)
			end
		end
		CombatService.DealDamage(player, character, humanoid, skill.Damage, {
			Stun = skill.Stun,
			Knockback = knockback,
		})
	end
end

function SkillKinds.DashStrike(player: Player, character: Model, root: BasePart, skill, color: Color3)
	local duration = 0.25
	local direction = root.CFrame.LookVector
	applyKnockback(character, direction * (skill.Distance / duration))

	local alreadyHit = {}
	local elapsed = 0
	while elapsed < duration and root.Parent do
		elapsed += task.wait()
		Effects.Burst(root.Position, 2, color, 0.25)
		for _, humanoid in hitBox(root.CFrame, Vector3.new(6, 6, 6), character) do
			if not alreadyHit[humanoid] then
				alreadyHit[humanoid] = true
				CombatService.DealDamage(player, character, humanoid, skill.Damage, {
					Stun = skill.Stun,
					Knockback = direction * 25 + Vector3.new(0, 20, 0),
				})
			end
		end
	end
end

function SkillKinds.Beam(player: Player, character: Model, root: BasePart, skill, color: Color3)
	local origin = root.CFrame
	Effects.Beam(origin, skill.Range, skill.Width, color)
	local center = origin * CFrame.new(0, 0, -skill.Range / 2)
	for _, humanoid in hitBox(center, Vector3.new(skill.Width, skill.Width, skill.Range), character) do
		CombatService.DealDamage(player, character, humanoid, skill.Damage, {
			Stun = skill.Stun,
			Knockback = skill.Knockback and origin.LookVector * skill.Knockback + Vector3.new(0, 20, 0) or nil,
		})
	end
end

function SkillKinds.Barrage(player: Player, character: Model, root: BasePart, skill, color: Color3)
	for _ = 1, skill.Hits do
		if not getAlive(character) or isStunned(character) then
			return
		end
		Effects.Slash(root.CFrame, color)
		local center = root.CFrame * CFrame.new(0, 0, -3.5)
		for _, humanoid in hitBox(center, Vector3.new(6, 6, 7), character) do
			CombatService.DealDamage(player, character, humanoid, skill.Damage, { Stun = skill.Stun })
		end
		task.wait(skill.Interval)
	end
end

---------------------------------------------------------------------------
-- Actions demandées par les joueurs
---------------------------------------------------------------------------

local function onM1(player: Player, character: Model, root: BasePart)
	if character:GetAttribute("Blocking") then
		return
	end
	local state = getState(character)
	local t = os.clock()
	if t < state.nextM1 then
		return
	end
	if t - state.lastM1 > C.M1ComboReset then
		state.combo = 0
	end
	state.combo += 1
	state.lastM1 = t

	local isFinal = state.combo >= C.M1ComboLength
	state.nextM1 = t + (if isFinal then C.M1EndLag else C.M1Interval)
	Remotes.Cooldown:FireClient(player, "M1", state.nextM1 - t, state.combo)

	local data = DataService.Get(player)
	local style = data and data.Style and Styles.List[data.Style]
	Effects.Slash(root.CFrame, style and style.Color or Color3.new(1, 1, 1))

	local center = root.CFrame * CFrame.new(0, 0, -C.M1HitboxSize.Z / 2)
	for _, humanoid in hitBox(center, C.M1HitboxSize, character) do
		CombatService.DealDamage(player, character, humanoid, if isFinal then C.M1FinalDamage else C.M1Damage, {
			Stun = C.M1Stun,
			Knockback = if isFinal then root.CFrame.LookVector * C.FinalKnockback + Vector3.new(0, 20, 0) else nil,
		})
	end

	if isFinal then
		state.combo = 0
	end
end

local function onBlock(character: Model, blocking: boolean)
	if blocking and isStunned(character) then
		return
	end
	character:SetAttribute("Blocking", blocking)
	updateSpeed(character)
end

local function onSkill(player: Player, character: Model, root: BasePart, slot: number)
	if character:GetAttribute("Blocking") then
		return
	end
	local data = DataService.Get(player)
	if not data or not data.Style then
		return
	end
	local style = Styles.List[data.Style]
	local skill = style and style.Skills[slot]
	if not skill then
		return
	end
	if slot > ProgressionService.UnlockedSkillCount(data.Level) then
		Remotes.Notify:FireClient(player, `Compétence débloquée au niveau {Config.Progression.SkillUnlockLevels[slot]}`)
		return
	end

	local state = getState(character)
	local key = `Skill{slot}`
	local t = os.clock()
	if (state.cooldowns[key] or 0) > t then
		return
	end
	state.cooldowns[key] = t + skill.Cooldown
	Remotes.Cooldown:FireClient(player, key, skill.Cooldown)

	SkillKinds[skill.Kind](player, character, root, skill, style.Color)
end

local function onCombat(player: Player, action: unknown, arg: unknown)
	local character = player.Character
	local _, root = getAlive(character)
	if not character or not root then
		return
	end

	if action == "Block" then
		onBlock(character, arg == true)
		return
	end
	if isStunned(character) then
		return
	end

	if action == "M1" then
		onM1(player, character, root)
	elseif action == "Skill" and typeof(arg) == "number" and arg == math.floor(arg) and arg >= 1 and arg <= 4 then
		onSkill(player, character, root, arg)
	end
end

function CombatService.Init() end

function CombatService.Start()
	Remotes.Combat.OnServerEvent:Connect(onCombat)

	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		CombatService.TrackHumanoid(humanoid, false)
	end

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(onCharacter)
		if player.Character then
			task.spawn(onCharacter, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
end

return CombatService
