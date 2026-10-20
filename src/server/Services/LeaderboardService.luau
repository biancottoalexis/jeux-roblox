-- Classement mondial (tous les serveurs) par niveau et par kills, plus le
-- classement des ordres. Utilise des OrderedDataStores.
-- Si les DataStores ne sont pas accessibles (Studio sans "API Services"),
-- le classement montre seulement les joueurs du serveur.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local OrderService = require(script.Parent.OrderService)

local LeaderboardService = {}

local L = Config.Leaderboard
local REQUEST_COOLDOWN = 2

-- Chaque statistique classée : nom dans les données du joueur -> DataStore
local STATS = {
	Level = L.LevelStore,
	Kills = L.KillsStore,
}

type Entry = { Name: string, Value: number }

local stores: { [string]: OrderedDataStore } = {}
local cache: { [string]: { Entry } } = { Level = {}, Kills = {} }
-- Dernière valeur envoyée pour chaque joueur, pour ne pas réécrire pour rien
local written: { [Player]: { [string]: number } } = {}
local names: { [number]: string } = {}
local lastRequest: { [Player]: number } = {}

local function nameFor(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = if ok then name else "???"
	return names[userId]
end

local function writePlayer(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	written[player] = written[player] or {}
	for stat, _ in STATS do
		local store = stores[stat]
		local value = data[stat]
		if store and written[player][stat] ~= value then
			local ok = pcall(function()
				store:SetAsync(tostring(player.UserId), value)
			end)
			if ok then
				written[player][stat] = value
			end
		end
	end
end

-- Classement des joueurs présents sur ce serveur (solution de secours)
local function localTop(stat: string): { Entry }
	local list = {}
	for _, player in Players:GetPlayers() do
		local data = DataService.Get(player)
		if data then
			table.insert(list, { Name = player.DisplayName, Value = data[stat] })
		end
	end
	table.sort(list, function(a, b)
		return a.Value > b.Value
	end)
	while #list > L.Size do
		table.remove(list)
	end
	return list
end

local function readTop(stat: string): { Entry }
	local store = stores[stat]
	if store then
		local ok, page = pcall(function()
			return store:GetSortedAsync(false, L.Size):GetCurrentPage()
		end)
		if ok then
			local list = {}
			for _, entry in page do
				local userId = tonumber(entry.key)
				table.insert(list, { Name = if userId then nameFor(userId) else "???", Value = entry.value })
			end
			if #list > 0 then
				return list
			end
		end
	end
	return localTop(stat)
end

local function refresh()
	for _, player in Players:GetPlayers() do
		writePlayer(player)
	end
	for stat in STATS do
		cache[stat] = readTop(stat)
	end
end

local function onRequest(player: Player)
	local t = os.clock()
	if lastRequest[player] and t - lastRequest[player] < REQUEST_COOLDOWN then
		return
	end
	lastRequest[player] = t
	Remotes.Leaderboard:FireClient(player, {
		Level = cache.Level,
		Kills = cache.Kills,
		Orders = OrderService.GetRanking(),
	})
end

function LeaderboardService.Init()
	for stat, storeName in STATS do
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(storeName)
		end)
		if ok then
			stores[stat] = store
		end
	end
end

function LeaderboardService.Start()
	Remotes.Leaderboard.OnServerEvent:Connect(onRequest)

	DataService.PlayerLoaded:Connect(function(player)
		names[player.UserId] = player.DisplayName
	end)
	Players.PlayerRemoving:Connect(function(player)
		writePlayer(player)
		written[player] = nil
		lastRequest[player] = nil
	end)

	task.spawn(function()
		task.wait(10) -- laisse le temps aux premiers joueurs de charger
		while true do
			refresh()
			task.wait(L.RefreshInterval)
		end
	end)
end

return LeaderboardService
