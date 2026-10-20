-- Ordres de chevaliers-mages : rejoindre un ordre, points de mérite et
-- classement mondial des ordres.
-- Chaque ordre est aussi une équipe Roblox (Teams) : le nom des membres
-- prend la couleur de l'ordre dans la liste des joueurs.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Teams = game:GetService("Teams")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Orders = require(Shared.Orders)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local CombatService = require(script.Parent.CombatService)

local OrderService = {}

local O = Config.Orders
local JOIN_COOLDOWN = 1

local store: OrderedDataStore? = nil
local teams: { [string]: Team } = {}
local lastJoin: { [Player]: number } = {}
-- Points pas encore envoyés au classement mondial
local pending: { [string]: number } = {}
-- Points gagnés sur ce serveur (utilisés si le classement mondial est indisponible)
local sessionTotals: { [string]: number } = {}
local ranking: { { Id: string, Value: number } } = {}
local warned = false

local function updateNameTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local existing = head:FindFirstChild("OrderTag")
	if existing then
		existing:Destroy()
	end

	local data = DataService.Get(player)
	local order = data and data.Order and Orders.List[data.Order]
	if not order then
		return
	end

	local tag = Instance.new("BillboardGui")
	tag.Name = "OrderTag"
	tag.Size = UDim2.fromOffset(200, 24)
	tag.StudsOffset = Vector3.new(0, 2.6, 0)
	tag.MaxDistance = 60

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = order.DisplayName
	label.TextColor3 = order.Color
	label.TextStrokeTransparency = 0.3
	label.Parent = tag

	tag.Parent = head
end

local function applyTeam(player: Player)
	local data = DataService.Get(player)
	local team = data and data.Order and teams[data.Order]
	if team then
		player.Team = team
		player.Neutral = false
	else
		player.Team = nil :: any
		player.Neutral = true
	end
	updateNameTag(player)
end

local function join(player: Player, orderId: unknown)
	if typeof(orderId) ~= "string" or not Orders.List[orderId] then
		return
	end
	local t = os.clock()
	if lastJoin[player] and t - lastJoin[player] < JOIN_COOLDOWN then
		return
	end
	lastJoin[player] = t

	local data = DataService.Get(player)
	if not data or data.Order == orderId then
		return
	end
	if data.Level < O.MinLevel then
		Remotes.Notify:FireClient(player, `Il faut être niveau {O.MinLevel} pour rejoindre un ordre.`)
		return
	end
	local cost = if data.Order then O.ChangeCost else 0
	if data.Gold < cost then
		Remotes.Notify:FireClient(player, `Changer d'ordre coûte {cost} 🪙.`)
		return
	end

	DataService.Update(player, function(d)
		d.Gold -= cost
		d.Order = orderId
	end)
	applyTeam(player)
	Remotes.Notify:FireClient(player, `Bienvenue dans l'{Orders.List[orderId].DisplayName} !`)
end

-- Ajoute des points de mérite au joueur et à son ordre
function OrderService.AddMerit(player: Player, amount: number)
	local data = DataService.Get(player)
	if not data or not data.Order then
		return
	end
	local orderId = data.Order
	DataService.Update(player, function(d)
		d.Merit += amount
	end)
	pending[orderId] = (pending[orderId] or 0) + amount
	sessionTotals[orderId] = (sessionTotals[orderId] or 0) + amount
end

-- Classement des ordres, du meilleur au moins bon : { { Id, Value } }
function OrderService.GetRanking()
	return ranking
end

local function flush()
	if not store then
		return
	end
	for orderId, amount in pending do
		if amount > 0 then
			local ok, err = pcall(function()
				(store :: OrderedDataStore):IncrementAsync(orderId, amount)
			end)
			if ok then
				pending[orderId] -= amount
			elseif not warned then
				warned = true -- un seul avertissement (en Studio sans accès aux API, ça échoue à chaque fois)
				warn("[OrderService] Envoi du mérite impossible, le classement des ordres reste local :", err)
			end
		end
	end
end

local function refreshRanking()
	local totals = {}
	local fromStore = false
	if store then
		local ok, page = pcall(function()
			return (store :: OrderedDataStore):GetSortedAsync(false, #Orders.Order):GetCurrentPage()
		end)
		if ok then
			fromStore = true
			for _, entry in page do
				totals[entry.key] = entry.value
			end
		end
	end
	if not fromStore then
		totals = sessionTotals
	end

	local list = {}
	for _, orderId in Orders.Order do
		-- On ajoute les points pas encore envoyés pour que le classement soit à jour
		local value = (totals[orderId] or 0) + (if fromStore then pending[orderId] or 0 else 0)
		table.insert(list, { Id = orderId, Value = value })
	end
	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)
	ranking = list
end

function OrderService.Init()
	for _, orderId in Orders.Order do
		local order = Orders.List[orderId]
		local team = Instance.new("Team")
		team.Name = order.DisplayName
		team.TeamColor = order.TeamColor
		team.AutoAssignable = false
		team.Parent = Teams
		teams[orderId] = team
	end

	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.Leaderboard.OrderStore)
	end)
	if ok then
		store = result
	end
	refreshRanking()
end

function OrderService.Start()
	Remotes.Order.OnServerEvent:Connect(join)

	DataService.PlayerLoaded:Connect(applyTeam)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 5)
			updateNameTag(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastJoin[player] = nil
	end)

	CombatService.Killed:Connect(function(killer: Player, kind: string)
		if kind == "Player" then
			OrderService.AddMerit(killer, O.MeritPerKill)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(O.FlushInterval)
			flush()
			refreshRanking()
		end
	end)

	game:BindToClose(flush)
end

return OrderService
