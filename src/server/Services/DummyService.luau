-- Mannequins d'entraînement : pour tester le combat seul et gagner un peu d'XP.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)

local CombatService = require(script.Parent.CombatService)

local DummyService = {}

local folder: Folder

local function spawnDummy(position: Vector3)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[DummyService] Impossible de créer un mannequin :", model)
		return
	end

	model.Name = "Mannequin"
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayName = "Mannequin d'entraînement"
	humanoid.MaxHealth = 150
	humanoid.Health = 150
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.rad(-90), 0))
	model.Parent = folder

	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	root:SetNetworkOwner(nil) -- le serveur garde le contrôle de sa physique

	CombatService.TrackHumanoid(humanoid, true)

	humanoid.Died:Once(function()
		task.wait(Config.Dummies.RespawnTime)
		model:Destroy()
		spawnDummy(position)
	end)
end

function DummyService.Init()
	folder = Instance.new("Folder")
	folder.Name = "Mannequins"
	folder.Parent = workspace
end

function DummyService.Start()
	for _, position in Config.Dummies.Positions do
		task.spawn(spawnDummy, position)
	end
end

return DummyService
