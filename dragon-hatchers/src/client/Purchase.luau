-- Ouvre la fenêtre d'achat Roblox pour un Game Pass ou un Developer Product,
-- et récupère les vrais prix configurés sur Roblox.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Monetization"))

local Toast = require(script.Parent.Toast)

local Purchase = {}

local prices: { [string]: number } = {}

function Purchase.Item(kind: string, key: string)
	if kind == "Pass" then
		return Monetization.GamePasses[key]
	end
	return Monetization.Products[key]
end

function Purchase.Prompt(kind: string, key: string)
	local item = Purchase.Item(kind, key)
	if not item or not Monetization.IsSellable(item) then
		Toast.Show("Bientôt disponible !")
		return
	end
	local player = Players.LocalPlayer
	if kind == "Pass" then
		MarketplaceService:PromptGamePassPurchase(player, item.Id)
	else
		MarketplaceService:PromptProductPurchase(player, item.Id)
	end
end

-- Prix affiché : le vrai prix Roblox s'il est connu, sinon celui de Monetization.luau
function Purchase.PriceText(kind: string, key: string): string
	local item = Purchase.Item(kind, key)
	return `R$ {prices[kind .. key] or item.Price}`
end

-- Va chercher les vrais prix (une seule fois) puis appelle onDone
function Purchase.LoadPrices(onDone: () -> ())
	task.spawn(function()
		local function load(kind: string, key: string, item)
			if item.Id == 0 then
				return
			end
			local infoType = if kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(item.Id, infoType)
			end)
			if ok and info and info.PriceInRobux then
				prices[kind .. key] = info.PriceInRobux
			end
		end
		for key, item in Monetization.GamePasses do
			load("Pass", key, item)
		end
		for key, item in Monetization.Products do
			load("Product", key, item)
		end
		onDone()
	end)
end

return Purchase
