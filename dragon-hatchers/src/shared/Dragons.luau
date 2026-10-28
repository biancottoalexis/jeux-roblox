-- Les dragons : raretés, mutations, espèces et calcul de leur production.
--
-- Un dragon possédé par un joueur est une petite table :
--   { Id = "12", S = "PrairieCommun", L = 1, M = "Normal" }
--   S = espèce, L = niveau (1 à 5, monte par fusion), M = mutation

local Config = require(script.Parent.Config)

local Dragons = {}

Dragons.Rarities = {
	Commun = { Order = 1, DisplayName = "Commun", Weight = 60, Multiplier = 1, Color = Color3.fromRGB(200, 200, 200) },
	Rare = { Order = 2, DisplayName = "Rare", Weight = 30, Multiplier = 3, Color = Color3.fromRGB(80, 160, 255) },
	Epique = { Order = 3, DisplayName = "Épique", Weight = 9, Multiplier = 10, Color = Color3.fromRGB(190, 90, 255) },
	Legendaire = { Order = 4, DisplayName = "Légendaire", Weight = 1, Multiplier = 40, Color = Color3.fromRGB(255, 200, 40) },
}
Dragons.RarityOrder = { "Commun", "Rare", "Epique", "Legendaire" }

-- Les mutations s'ajoutent à la rareté. Chance = 1 sur "OneIn".
Dragons.Mutations = {
	Normal = { Order = 1, DisplayName = "", OneIn = nil, Multiplier = 1 },
	Dore = { Order = 2, DisplayName = "Doré", OneIn = 50, Multiplier = 3, Color = Color3.fromRGB(255, 200, 40) },
	ArcEnCiel = { Order = 3, DisplayName = "Arc-en-ciel", OneIn = 500, Multiplier = 10, Color = Color3.fromRGB(255, 120, 220) },
	Cosmique = { Order = 4, DisplayName = "Cosmique", OneIn = 10000, Multiplier = 50, Color = Color3.fromRGB(40, 20, 90) },
}
-- De la plus commune à la plus rare (la fusion fait monter d'un cran)
Dragons.MutationOrder = { "Normal", "Dore", "ArcEnCiel", "Cosmique" }

-- Production de base d'un dragon Commun niveau 1 dans chaque zone (or par seconde)
local ZONE_BASE = { 1, 25, 600, 15000, 400000 }

local function species(zone: number, rarity: string, name: string, color: Color3, accent: Color3)
	return {
		DisplayName = name,
		Zone = zone,
		Rarity = rarity,
		Color = color,
		Accent = accent,
		BaseProduction = ZONE_BASE[zone] * Dragons.Rarities[rarity].Multiplier,
	}
end

Dragons.Species = {
	-- 🌿 Prairie
	PrairieCommun = species(1, "Commun", "Dragonnet des Prés", Color3.fromRGB(120, 200, 90), Color3.fromRGB(230, 240, 150)),
	PrairieRare = species(1, "Rare", "Dragon Feuillu", Color3.fromRGB(60, 160, 70), Color3.fromRGB(250, 200, 80)),
	PrairieEpique = species(1, "Epique", "Dragon Sylvestre", Color3.fromRGB(40, 110, 60), Color3.fromRGB(240, 120, 200)),
	PrairieLegendaire = species(1, "Legendaire", "Wyverne d'Émeraude", Color3.fromRGB(20, 200, 140), Color3.fromRGB(255, 255, 255)),
	-- 🌋 Volcan
	VolcanCommun = species(2, "Commun", "Salamandre de Braise", Color3.fromRGB(230, 110, 50), Color3.fromRGB(255, 220, 120)),
	VolcanRare = species(2, "Rare", "Dragon Cendré", Color3.fromRGB(90, 80, 80), Color3.fromRGB(255, 120, 40)),
	VolcanEpique = species(2, "Epique", "Dragon de Magma", Color3.fromRGB(200, 40, 30), Color3.fromRGB(255, 180, 40)),
	VolcanLegendaire = species(2, "Legendaire", "Wyverne Infernale", Color3.fromRGB(30, 20, 20), Color3.fromRGB(255, 60, 20)),
	-- 🌊 Océan glacé
	OceanCommun = species(3, "Commun", "Dragonnet des Flots", Color3.fromRGB(70, 160, 230), Color3.fromRGB(220, 240, 255)),
	OceanRare = species(3, "Rare", "Dragon de Givre", Color3.fromRGB(170, 220, 250), Color3.fromRGB(80, 140, 255)),
	OceanEpique = species(3, "Epique", "Serpent des Abysses", Color3.fromRGB(20, 60, 130), Color3.fromRGB(60, 255, 220)),
	OceanLegendaire = species(3, "Legendaire", "Léviathan de Glace", Color3.fromRGB(230, 250, 255), Color3.fromRGB(100, 200, 255)),
	-- ⚡ Royaume du Ciel
	CielCommun = species(4, "Commun", "Dragonnet des Nuages", Color3.fromRGB(240, 240, 250), Color3.fromRGB(150, 200, 255)),
	CielRare = species(4, "Rare", "Dragon Tempête", Color3.fromRGB(90, 100, 140), Color3.fromRGB(255, 240, 80)),
	CielEpique = species(4, "Epique", "Dragon Tonnerre", Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 60, 200)),
	CielLegendaire = species(4, "Legendaire", "Wyverne Céleste", Color3.fromRGB(150, 220, 255), Color3.fromRGB(255, 250, 200)),
	-- 🌌 Néant cosmique
	NeantCommun = species(5, "Commun", "Dragon Stellaire", Color3.fromRGB(60, 50, 120), Color3.fromRGB(200, 200, 255)),
	NeantRare = species(5, "Rare", "Dragon Nébuleuse", Color3.fromRGB(150, 60, 200), Color3.fromRGB(80, 220, 255)),
	NeantEpique = species(5, "Epique", "Dragon Éclipse", Color3.fromRGB(15, 15, 25), Color3.fromRGB(255, 160, 40)),
	NeantLegendaire = species(5, "Legendaire", "Dragon Primordial", Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 80, 255)),
}

-- Espèces de chaque zone, par rareté : SpeciesByZone[zone][rarity] = id
Dragons.SpeciesByZone = {}
for id, def in Dragons.Species do
	Dragons.SpeciesByZone[def.Zone] = Dragons.SpeciesByZone[def.Zone] or {}
	Dragons.SpeciesByZone[def.Zone][def.Rarity] = id
end

export type Dragon = { Id: string, S: string, L: number, M: string }

-- Or produit par seconde par un dragon (sans les bonus du joueur)
function Dragons.Production(dragon: Dragon): number
	local def = Dragons.Species[dragon.S]
	local mutation = Dragons.Mutations[dragon.M]
	if not def or not mutation then
		return 0
	end
	return def.BaseProduction * Config.Fusion.LevelMultiplier ^ (dragon.L - 1) * mutation.Multiplier
end

-- Deux dragons ont la même clé s'ils peuvent être fusionnés ensemble
function Dragons.Key(dragon: Dragon): string
	return `{dragon.S}|{dragon.L}|{dragon.M}`
end

-- Nom complet : "Dragon de Magma Doré Niv. 2"
function Dragons.FullName(dragon: Dragon): string
	local def = Dragons.Species[dragon.S]
	local mutation = Dragons.Mutations[dragon.M]
	local name = def and def.DisplayName or "?"
	if mutation and mutation.DisplayName ~= "" then
		name ..= ` {mutation.DisplayName}`
	end
	if dragon.L > 1 then
		name ..= ` Niv. {dragon.L}`
	end
	return name
end

-- Chances de rareté d'un œuf (en %), avec le bonus « Chasseur de Légendaires »
function Dragons.RarityChances(legendaryMultiplier: number?): { [string]: number }
	local weights = {}
	local total = 0
	for _, rarity in Dragons.RarityOrder do
		local weight = Dragons.Rarities[rarity].Weight
		if rarity == "Legendaire" then
			weight *= legendaryMultiplier or 1
		end
		weights[rarity] = weight
		total += weight
	end
	for rarity, weight in weights do
		weights[rarity] = weight / total * 100
	end
	return weights
end

function Dragons.RollRarity(rng: Random, legendaryMultiplier: number?): string
	local chances = Dragons.RarityChances(legendaryMultiplier)
	local pick = rng:NextNumber() * 100
	for _, rarity in Dragons.RarityOrder do
		pick -= chances[rarity]
		if pick <= 0 then
			return rarity
		end
	end
	return "Commun"
end

-- Tire une mutation. luck multiplie les chances (2 = deux fois plus de chances).
function Dragons.RollMutation(rng: Random, luck: number): string
	-- On teste de la plus rare à la plus commune
	for i = #Dragons.MutationOrder, 2, -1 do
		local id = Dragons.MutationOrder[i]
		local oneIn = Dragons.Mutations[id].OneIn :: number
		if rng:NextNumber() < math.min(0.5, luck / oneIn) then
			return id
		end
	end
	return "Normal"
end

-- Mutation suivante (pour la fusion) ou nil si c'est déjà la meilleure
function Dragons.NextMutation(mutation: string): string?
	local order = Dragons.Mutations[mutation].Order
	return Dragons.MutationOrder[order + 1]
end

return Dragons
