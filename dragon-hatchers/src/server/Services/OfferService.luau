-- Propose le bon achat au bon moment : nid plein -> « Grand nid », beaucoup
-- d'œufs ouverts -> « Triple éclosion », etc. C'est ce qui multiplie les ventes.
-- Une proposition n'apparaît qu'une fois par partie, et jamais deux de suite
-- trop rapprochées.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Monetization = require(Shared.Monetization)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)

local OfferService = {}

type Choice = { Kind: "Pass" | "Product", Key: string, Message: string }

-- Pour chaque situation, les achats proposés dans l'ordre (le premier
-- disponible et pas encore possédé est choisi)
local SITUATIONS: { [string]: { Choice } } = {
	NestFull = {
		{ Kind = "Pass", Key = "BigNest", Message = "Ton nid est plein ! Agrandis-le de 10 places :" },
		{ Kind = "Pass", Key = "GiantNest", Message = "Ton nid est encore plein ! Passe au nid géant (+25 places) :" },
	},
	Hatches = {
		{ Kind = "Pass", Key = "TripleHatch", Message = "Tu ouvres beaucoup d'œufs ! Ouvre-les 3 par 3 :" },
		{ Kind = "Pass", Key = "OctoHatch", Message = "Passe à 8 œufs d'un coup :" },
		{ Kind = "Pass", Key = "AutoHatch", Message = "Laisse les œufs s'ouvrir tout seuls :" },
	},
	Fusions = {
		{ Kind = "Pass", Key = "AutoFusion", Message = "Marre de fusionner à la main ? Tes dragons fusionnent tout seuls avec :" },
	},
	NoGold = {
		{ Kind = "Product", Key = "GoldSmall", Message = "Pas assez d'or ? Récupère 15 minutes de production tout de suite :" },
	},
	ZoneClose = {
		{ Kind = "Product", Key = "UnlockZone", Message = "Tu y es presque ! Débloque la zone suivante maintenant :" },
	},
	StarterPack = {
		{ Kind = "Product", Key = "StarterPack", Message = "Offre de bienvenue, une seule fois :" },
	},
}

local lastOffer: { [Player]: number } = {}
local shown: { [Player]: { [string]: boolean } } = {}

local function isAvailable(player: Player, choice: Choice): boolean
	if choice.Kind == "Pass" then
		local pass = Monetization.GamePasses[choice.Key]
		if not Monetization.IsSellable(pass) or MonetizationService.HasPass(player, choice.Key) then
			return false
		end
		return pass.Requires == nil or MonetizationService.HasPass(player, pass.Requires)
	end
	local product = Monetization.Products[choice.Key]
	if not Monetization.IsSellable(product) then
		return false
	end
	if choice.Key == "StarterPack" then
		local data = DataService.Get(player)
		return data ~= nil and not data.StarterPackBought
	end
	return true
end

-- Propose un achat adapté à la situation, si c'est le bon moment
function OfferService.Trigger(player: Player, situation: string)
	local choices = SITUATIONS[situation]
	if not choices then
		return
	end
	local t = os.clock()
	if lastOffer[player] and t - lastOffer[player] < Config.Offers.Cooldown then
		return
	end
	shown[player] = shown[player] or {}

	for _, choice in choices do
		local id = `{choice.Kind}:{choice.Key}`
		if not shown[player][id] and isAvailable(player, choice) then
			shown[player][id] = true
			lastOffer[player] = t
			Remotes.Offer:FireClient(player, choice.Kind, choice.Key, choice.Message)
			return
		end
	end
end

function OfferService.Init() end

function OfferService.Start()
	DataService.PlayerLoaded:Connect(function(player, data)
		if data.StarterPackBought or os.time() - data.FirstJoin > Config.Offers.StarterPackWindow then
			return
		end
		task.delay(Config.Offers.StarterPackDelay, function()
			if player.Parent then
				OfferService.Trigger(player, "StarterPack")
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastOffer[player] = nil
		shown[player] = nil
	end)
end

return OfferService
