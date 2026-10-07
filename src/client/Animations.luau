-- Joue les animations définies dans Config.Animations (si elles existent).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Animations = {}

local player = Players.LocalPlayer
local tracks: { [string]: AnimationTrack } = {}

local function loadTrack(animator: Animator, name: string, id: string)
	if id == "" then
		return
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if ok then
		tracks[name] = track
	else
		warn(`[Animations] Impossible de charger {name} :`, track)
	end
end

local function onCharacter(character: Model)
	tracks = {}
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local animator = humanoid:WaitForChild("Animator") :: Animator

	for index, id in Config.Animations.M1 do
		loadTrack(animator, `M1_{index}`, id)
	end
	loadTrack(animator, "Block", Config.Animations.Block)
	loadTrack(animator, "Dash", Config.Animations.Dash)
	loadTrack(animator, "Skill", Config.Animations.Skill)

	if tracks.Block then
		tracks.Block.Looped = true
	end
end

function Animations.Play(name: string)
	local track = tracks[name]
	if track then
		track:Play(0.05)
	end
end

function Animations.Stop(name: string)
	local track = tracks[name]
	if track then
		track:Stop(0.1)
	end
end

function Animations.Start()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
end

return Animations
