-- Sauvegarde et chargement des données des joueurs (DataStore).
-- Si les DataStores ne sont pas accessibles (Studio sans "API Services"),
-- les données restent en mémoire : le jeu marche mais rien n'est sauvegardé.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataService = {}

local store: DataStore? = nil
local profiles: { [Player]: any } = {}
-- Joueurs dont le chargement a échoué en Studio : on ne sauvegarde pas pour
-- ne pas écraser leurs vraies données
local noSave: { [Player]: boolean } = {}
local loadedEvent = Instance.new("BindableEvent")

-- Se déclenche quand les données d'un joueur sont prêtes : (player, data)
DataService.PlayerLoaded = loadedEvent.Event

local function defaultData()
	return {
		Gold = 0,
		Level = 1,
		XP = 0,
		Grimoire = nil,
		Spins = Config.Progression.StartingSpins,
		Kills = 0,
		Deaths = 0,
		-- Achats déjà crédités, pour ne jamais donner deux fois le même achat
		Receipts = {},
	}
end

local function reconcile(data)
	for key, value in defaultData() do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function withRetries(label: string, fn: () -> any): (boolean, any)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(`[DataService] {label} échec (essai {attempt}) : {result}`)
		task.wait(attempt * 2)
	end
	return false, nil
end

local function keyFor(player: Player): string
	return `Player_{player.UserId}`
end

-- Ce que le client a le droit de voir
local function snapshot(data)
	return {
		Gold = data.Gold,
		Level = data.Level,
		XP = data.XP,
		XPNeeded = Config.XPForLevel(data.Level),
		Grimoire = data.Grimoire,
		Spins = data.Spins,
		Kills = data.Kills,
	}
end

local function refresh(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Niveau.Value = data.Level
		leaderstats.Or.Value = data.Gold
	end
	Remotes.Data:FireClient(player, snapshot(data))
end

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local level = Instance.new("IntValue")
	level.Name = "Niveau"
	level.Parent = leaderstats

	local gold = Instance.new("IntValue")
	gold.Name = "Or"
	gold.Parent = leaderstats

	leaderstats.Parent = player
end

local function onPlayerAdded(player: Player)
	local data
	if store then
		local ok, result = withRetries("chargement", function()
			return (store :: DataStore):GetAsync(keyFor(player))
		end)
		if ok then
			data = result
		elseif RunService:IsStudio() then
			warn("[DataService] Chargement impossible en Studio : active \"Enable Studio Access to API Services\". Données temporaires utilisées.")
			noSave[player] = true
		else
			player:Kick("Impossible de charger tes données. Réessaie dans un instant.")
			return
		end
	end
	data = reconcile(data or defaultData())

	if not player.Parent then
		return -- le joueur est parti pendant le chargement
	end

	profiles[player] = data
	createLeaderstats(player)
	refresh(player)
	loadedEvent:Fire(player, data)
end

function DataService.Get(player: Player)
	return profiles[player]
end

-- Modifie les données puis met à jour l'affichage du joueur.
-- Exemple : DataService.Update(player, function(data) data.Gold += 10 end)
function DataService.Update(player: Player, fn: (any) -> ())
	local data = profiles[player]
	if not data then
		return false
	end
	fn(data)
	refresh(player)
	return true
end

function DataService.Save(player: Player): boolean
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return data ~= nil
	end
	local ok = withRetries("sauvegarde", function()
		(store :: DataStore):UpdateAsync(keyFor(player), function()
			return data
		end)
	end)
	return ok
end

function DataService.Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore indisponible, les données ne seront pas sauvegardées :", result)
	end
end

function DataService.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Le client redemande ses données au démarrage (au cas où il les aurait ratées)
	Remotes.Data.OnServerEvent:Connect(refresh)

	Players.PlayerRemoving:Connect(function(player)
		DataService.Save(player)
		profiles[player] = nil
		noSave[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Config.Data.AutosaveInterval)
			for player in profiles do
				task.spawn(DataService.Save, player)
			end
		end
	end)

	-- Sauvegarde tout le monde quand le serveur s'arrête
	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				DataService.Save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
