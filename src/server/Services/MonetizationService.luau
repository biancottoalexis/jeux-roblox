-- Gère les achats Robux : Game Passes et Developer Products.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)

local MonetizationService = {}

local MAX_STORED_RECEIPTS = 100

local passCache: { [Player]: { [string]: boolean } } = {}

function MonetizationService.HasPass(player: Player, passKey: string): boolean
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

	local _, product = Monetization.FindProductById(receipt.ProductId)
	if not product then
		warn("[Monetization] Produit inconnu :", receipt.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	DataService.Update(player, function(d)
		if product.Spins then
			d.Spins += product.Spins
		end
		if product.Gold then
			d.Gold += product.Gold
		end
		d.Receipts[receipt.PurchaseId] = os.time()
		pruneReceipts(d.Receipts)
	end)

	if not DataService.Save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	Remotes.Notify:FireClient(player, `Merci pour ton achat : {product.Name} !`)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.Init() end

function MonetizationService.Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for key, pass in Monetization.GamePasses do
			if pass.Id == passId then
				passCache[player] = passCache[player] or {}
				passCache[player][key] = true
				Remotes.Notify:FireClient(player, `{pass.Name} activé, merci !`)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		passCache[player] = nil
	end)
end

return MonetizationService
