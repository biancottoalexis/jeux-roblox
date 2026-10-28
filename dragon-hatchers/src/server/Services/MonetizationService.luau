-- Gère les achats Robux : Game Passes et Developer Products.
-- Les autres services disent quoi donner pour chaque produit avec
-- MonetizationService.OnProduct(clé, fonction).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local MAX_STORED_RECEIPTS = 100

local passCache: { [Player]: { [string]: boolean } } = {}
local handlers: { [string]: (Player, any) -> () } = {}
local passAddedEvent = Instance.new("BindableEvent")

-- (player, passKey) : un joueur vient d'acheter un Game Pass
MonetizationService.PassAdded = passAddedEvent.Event

local studioPasses = {}
if RunService:IsStudio() then
	for _, key in Monetization.StudioTestPasses do
		studioPasses[key] = true
	end
end

function MonetizationService.HasPass(player: Player, passKey: string): boolean
	if studioPasses[passKey] then
		return true
	end
	local pass = Monetization.GamePasses[passKey]
	if not pass or pass.Id == 0 then
		return false
	end

	local cache = passCache[player]
	if not cache then
		cache = {}
		passCache[player] = cache
	end
	if cache[passKey] ~= nil then
		return cache[passKey]
	end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
	end)
	if not ok then
		return false -- on réessaiera au prochain appel
	end
	cache[passKey] = owns
	return owns
end

-- Liste des Game Passes du joueur (pour l'interface)
local function ownedPasses(player: Player): { string }
	local owned = {}
	for key in Monetization.GamePasses do
		local cache = passCache[player]
		if studioPasses[key] or (cache and cache[key]) then
			table.insert(owned, key)
		end
	end
	return owned
end

-- Dit quoi donner quand un produit est acheté. fn(player, data) modifie data.
function MonetizationService.OnProduct(productKey: string, fn: (Player, any) -> ())
	handlers[productKey] = fn
end

local function pruneReceipts(receipts)
	local count = 0
	local oldestId, oldestTime = nil, math.huge
	for id, time in receipts do
		count += 1
		if time < oldestTime then
			oldestId, oldestTime = id, time
		end
	end
	if count > MAX_STORED_RECEIPTS and oldestId then
		receipts[oldestId] = nil
	end
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if data.Receipts[receipt.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local key, product = Monetization.FindProductById(receipt.ProductId)
	local handler = key and handlers[key]
	if not product or not handler then
		warn("[Monetization] Produit inconnu ou sans effet :", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(handler, player, data)
	if not ok then
		warn("[Monetization] Erreur en donnant le produit :", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.Receipts[receipt.PurchaseId] = os.time()
	pruneReceipts(data.Receipts)
	DataService.Refresh(player)

	if not DataService.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Remotes.Notify:FireClient(player, `Merci pour ton achat : {product.Name} !`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init()
	DataService.AddSnapshotField("Passes", ownedPasses)
end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	-- Vérifie tous les Game Passes du joueur dès son arrivée
	DataService.PlayerLoaded:Connect(function(player)
		for key in Monetization.GamePasses do
			MonetizationService.HasPass(player, key)
		end
		DataService.Refresh(player)
		for key in Monetization.GamePasses do
			if MonetizationService.HasPass(player, key) then
				passAddedEvent:Fire(player, key)
			end
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Monetization.GamePasses do
			if pass.Id == passId then
				passCache[player] = passCache[player] or {}
				passCache[player][key] = true
				Remotes.Notify:FireClient(player, `{pass.Name} activé, merci !`)
				DataService.Refresh(player)
				passAddedEvent:Fire(player, key)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
	end)
end

return MonetizationService
