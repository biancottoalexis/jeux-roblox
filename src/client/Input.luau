-- Contrôles du joueur (PC, manette et mobile).
--   Clic gauche : attaque     F : garde     Q : esquive
--   Z / X / C / V : compétences 1 à 4

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Movement = require(Shared.Movement)

local State = require(script.Parent.State)
local Animations = require(script.Parent.Animations)

local Input = {}

local player = Players.LocalPlayer
local C = Config.Combat

local SKILL_KEYS = {
	{ Enum.KeyCode.Z, Enum.KeyCode.ButtonX },
	{ Enum.KeyCode.X, Enum.KeyCode.ButtonY },
	{ Enum.KeyCode.C, Enum.KeyCode.DPadLeft },
	{ Enum.KeyCode.V, Enum.KeyCode.DPadRight },
}
local SKILL_TITLES = { "Z", "X", "C", "V" }

local function getCharacter(): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not root or humanoid.Health <= 0 then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function canAct(): boolean
	local character = getCharacter()
	if not character then
		return false
	end
	return (character:GetAttribute("StunnedUntil") or 0) <= workspace:GetServerTimeNow()
end

local function onM1(_, inputState)
	if inputState == Enum.UserInputState.Begin and canAct() and not State.IsOnCooldown("M1") then
		Remotes.Combat:FireServer("M1")
	end
	return Enum.ContextActionResult.Pass
end

local function onBlock(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		Remotes.Combat:FireServer("Block", true)
		Animations.Play("Block")
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		Remotes.Combat:FireServer("Block", false)
		Animations.Stop("Block")
	end
	return Enum.ContextActionResult.Sink
end

local function onDash(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local _, humanoid, root = getCharacter()
	if not humanoid or not root or not canAct() or State.IsOnCooldown("Dash") then
		return Enum.ContextActionResult.Sink
	end

	local direction = humanoid.MoveDirection
	if direction.Magnitude < 0.1 then
		direction = root.CFrame.LookVector
	end
	direction = (direction * Vector3.new(1, 0, 1)).Unit

	Movement.ApplyVelocity(root, direction * C.DashSpeed, C.DashDuration)
	State.SetCooldown("Dash", C.DashCooldown)
	Animations.Play("Dash")
	return Enum.ContextActionResult.Sink
end

local function makeSkillHandler(slot: number)
	return function(_, inputState)
		if inputState == Enum.UserInputState.Begin and canAct() and not State.IsOnCooldown(`Skill{slot}`) then
			Remotes.Combat:FireServer("Skill", slot)
		end
		return Enum.ContextActionResult.Sink
	end
end

function Input.Start()
	ContextActionService:BindAction("Attaque", onM1, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
	ContextActionService:BindAction("Garde", onBlock, true, Enum.KeyCode.F, Enum.KeyCode.ButtonL2)
	ContextActionService:BindAction("Esquive", onDash, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("Attaque", "⚔")
	ContextActionService:SetTitle("Garde", "🛡")
	ContextActionService:SetTitle("Esquive", "💨")

	for slot, keys in SKILL_KEYS do
		local name = `Competence{slot}`
		ContextActionService:BindAction(name, makeSkillHandler(slot), true, table.unpack(keys))
		ContextActionService:SetTitle(name, SKILL_TITLES[slot])
	end

	-- Le serveur nous pousse (coup reçu ou charge d'une compétence)
	Remotes.Knockback.OnClientEvent:Connect(function(velocity: Vector3, duration: number)
		local _, _, root = getCharacter()
		if root then
			Movement.ApplyVelocity(root, velocity, duration)
		end
	end)

	-- Animations confirmées par le serveur
	State.CooldownStarted:Connect(function(key, _, extra)
		if key == "M1" then
			Animations.Play(`M1_{extra}`)
		elseif string.sub(key, 1, 5) == "Skill" then
			Animations.Play("Skill")
		end
	end)
end

return Input
