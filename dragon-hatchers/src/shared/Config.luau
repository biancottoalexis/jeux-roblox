-- Réglages généraux du jeu. Modifie les valeurs ici pour équilibrer le jeu
-- sans toucher au reste du code.

local Config = {}

Config.Economy = {
	StartingGold = 150, -- de quoi ouvrir 3 œufs dès le début (et souvent fusionner tout de suite)
	ProductionTick = 1, -- l'or est versé toutes les secondes
	-- Un clic sur « Récolter » donne ce pourcentage de la production par seconde
	ClickShare = 0.15,
	MinClickGold = 1,
	MaxClicksPerSecond = 12, -- au-delà, les clics sont ignorés (anti-triche)
	PremiumBonus = 0.1, -- +10 % d'or pour les abonnés Roblox Premium
}

Config.OfflineEarnings = {
	MaxHours = 8, -- les dragons produisent au maximum 8 h quand le joueur est absent
	Rate = 0.5, -- à 50 % de leur production
	MinSeconds = 60, -- pas de message pour une absence de moins d'une minute
}

-- Le nid : nombre de dragons que l'on peut garder
Config.Nest = {
	-- Agrandissements achetés avec de l'or : { places au total, prix }
	Upgrades = {
		{ Slots = 12, Price = 0 },
		{ Slots = 15, Price = 1000 },
		{ Slots = 20, Price = 25000 },
		{ Slots = 25, Price = 500000 },
		{ Slots = 30, Price = 10000000 },
	},
}

Config.Hatch = {
	Cooldown = 2.6, -- temps minimum entre deux éclosions (durée de l'animation)
	FastCooldown = 0.9, -- avec le Game Pass « Éclosion rapide »
	AutoInterval = 3, -- éclosion automatique : un essai toutes les 3 secondes
	PromptDistance = 12, -- distance pour voir le bouton « Ouvrir »
}

Config.Fusion = {
	Required = 3, -- dragons identiques nécessaires
	MaxLevel = 5,
	LevelMultiplier = 4, -- chaque niveau produit x4
	MutationUpgradeChance = 0.02, -- 2 % de chance d'améliorer la mutation
	LuckyMutationUpgradeChance = 0.06, -- avec le Game Pass « Fusion chanceuse »
}

-- Dragons qui volent derrière le joueur
Config.Followers = {
	Count = 1,
	PassCount = 3, -- avec le Game Pass « Dragons qui suivent x3 »
}

Config.Movement = {
	WalkSpeed = 20,
	FastWalkSpeed = 40, -- avec le Game Pass « Vitesse x2 »
}

-- Propositions d'achat au bon moment (voir OfferService)
Config.Offers = {
	Cooldown = 300, -- pas plus d'une proposition toutes les 5 minutes
	StarterPackWindow = 3600, -- le pack du débutant est proposé pendant la première heure
	StarterPackDelay = 90, -- secondes de jeu avant de le proposer
	HatchesBeforeMultiHatch = 40,
	FusionsBeforeAutoFusion = 15,
}

Config.Data = {
	StoreName = "DragonData_v1",
	AutosaveInterval = 120,
}

-- Sons (IDs "rbxassetid://..." de la bibliothèque Roblox). Laisse vide pour aucun son.
Config.Sounds = {
	Hatch = "",
	Reveal = "",
	Rare = "",
	Fusion = "",
	Coin = "",
}

return Config
