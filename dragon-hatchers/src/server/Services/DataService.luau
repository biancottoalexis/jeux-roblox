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
local removingEvent = Instance.new("BindableEvent")
local snapshotFields: { [string]: (Player, any) -> any } = {}

-- Se déclenche quand les données d'un joueur sont prêtes : (player, data)
DataService.PlayerLoaded = loadedEvent.Event
-- Se déclenche juste avant la dernière sauvegarde d'un joueur qui part : (player, data)
DataService.PlayerRemoving = removingEvent.Event

local function defaultData()
	return {
		Gold = Config.Economy.StartingGold,
		TotalGold = 0, -- tout l'or gagné depuis le début (pour les classements)
		-- Dragons possédés : { [id] = { Id, S, L, M } } (voir Dragons.luau)
		Dragons = {},
		NextDragonId = 1,
		NestLevel = 1, -- index dans Config.Nest.Upgrades
		Zones = { Prairie = true },
		-- Potions actives : heure de fin (os.time())
		Potions = { Luck = 0, Gold = 0 },
		AutoHatch = false,
		LastOnline = 0,
		FirstJoin = 0,
		StarterPackBought = false,
		Stats = { Hatched = 0, Fused = 0, Clicks = 0 },
		-- Achats déjà crédités, pour ne jamais donner deux fois le même achat
		Receipts = {},
	}
end

local function reconcile(data, defaults)
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		elseif type(value) == "table" and type(data[key]) == "table" and next(value) ~= nil then
			reconcile(data[key], value)
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

-- Ce que le client a le droit de voir. L'or est envoyé à part (attribut
-- "Gold" du joueur) car il change chaque seconde.
local function snapshot(player: Player, data)
	local dragons = {}
	for _, dragon in data.Dragons do
		table.insert(dragons, dragon)
	end
	local view = {
		Dragons = dragons,
		NestLevel = data.NestLevel,
		Zones = data.Zones,
		Potions = data.Potions,
		AutoHatch = data.AutoHatch,
		StarterPackBought = data.StarterPackBought,
		Stats = data.Stats,
	}
	for name, fn in snapshotFields do
		view[name] = fn(player, data)
	end
	return view
end

local function refresh(player: Player)
	local data = profiles[player]
	if not data then
		return
	end
	Remotes.Data:FireClient(player, snapshot(player, data))
end

-- Ajoute un champ calculé à ce que le client reçoit (ex : la capacité du nid)
function DataService.AddSnapshotField(name: string, fn: (Player, any) -> any)
	snapshotFields[name] = fn
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
	data = reconcile(data or defaultData(), defaultData())
	if data.FirstJoin == 0 then
		data.FirstJoin = os.time()
	end

	if not player.Parent then
		return -- le joueur est parti pendant le chargement
	end

	profiles[player] = data
	loadedEvent:Fire(player, data)
	refresh(player)
end

function DataService.Get(player: Player)
	return profiles[player]
end

-- Modifie les données puis met à jour l'affichage du joueur.
-- Exemple : DataService.Update(player, function(data) data.NestLevel += 1 end)
function DataService.Update(player: Player, fn: (any) -> ())
	local data = profiles[player]
	if not data then
		return false
	end
	fn(data)
	refresh(player)
	return true
end

-- Renvoie les données au client sans rien changer
function DataService.Refresh(player: Player)
	refresh(player)
end

function DataService.Save(player: Player): boolean
	local data = profiles[player]
	if not data or not store or noSave[player] then
		return data ~= nil
	end
	data.LastOnline = os.time()
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
		local data = profiles[player]
		if data then
			removingEvent:Fire(player, data)
		end
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
