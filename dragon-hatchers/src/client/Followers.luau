-- Dessine les dragons qui volent derrière chaque joueur. Le serveur écrit la
-- liste dans l'attribut "Followers" du joueur, chaque client les affiche.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DragonModel = require(script.Parent.DragonModel)

local Followers = {}

local SCALE = 0.55
-- Places autour du joueur (derrière, à gauche, à droite)
local OFFSETS = {
	Vector3.new(-3.5, 2.5, 4.5),
	Vector3.new(3.5, 2.5, 4.5),
	Vector3.new(0, 4, 7.5),
}

type Follower = { Rig: DragonModel.Rig, Current: CFrame? }

local folder: Folder
local byPlayer: { [Player]: { Follower } } = {}

local function clear(player: Player)
	local followers = byPlayer[player]
	if followers then
		for _, follower in followers do
			follower.Rig.Model:Destroy()
		end
	end
	byPlayer[player] = nil
end

local function rebuild(player: Player)
	clear(player)
	local raw = player:GetAttribute("Followers")
	if typeof(raw) ~= "string" then
		return
	end
	local ok, list = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok then
		return
	end
	local followers = {}
	for i, dragon in list do
		if i > #OFFSETS then
			break
		end
		local rig = DragonModel.Build(dragon, SCALE)
		rig.Model.Parent = folder
		table.insert(followers, { Rig = rig, Current = nil })
	end
	byPlayer[player] = followers
end

local function watch(player: Player)
	player:GetAttributeChangedSignal("Followers"):Connect(function()
		rebuild(player)
	end)
	rebuild(player)
end

local function step(dt: number)
	local t = os.clock()
	local alpha = 1 - math.exp(-dt * 7)
	for player, followers in byPlayer do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		for i, follower in followers do
			local model = follower.Rig.Model
			if not root then
				model.Parent = nil
				follower.Current = nil
				continue
			end
			model.Parent = folder

			local bob = math.sin(t * 2 + i) * 0.4
			local target = root.CFrame * CFrame.new(OFFSETS[i] + Vector3.new(0, bob, 0))
			-- Le dragon regarde dans la même direction que le joueur
			local goal = CFrame.lookAt(target.Position, target.Position + root.CFrame.LookVector)
			local current = follower.Current
			if not current or (current.Position - goal.Position).Magnitude > 60 then
				current = goal -- téléportation : on ne fait pas traverser la carte
			end
			follower.Current = (current :: CFrame):Lerp(goal, alpha)
			DragonModel.Pose(follower.Rig, follower.Current :: CFrame, t + i)
		end
	end
end

function Followers.Start()
	folder = Instance.new("Folder")
	folder.Name = "FollowerDragons"
	folder.Parent = workspace

	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(clear)
	RunService.RenderStepped:Connect(step)
end

return Followers
