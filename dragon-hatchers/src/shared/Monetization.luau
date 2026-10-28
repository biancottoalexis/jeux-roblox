-- Tout ce qui rapporte des Robux.
--
-- Remplace chaque Id = 0 par l'ID que Roblox te donne quand tu crées le
-- Game Pass ou le Developer Product (voir README, étape « Monétisation »).
-- Tant qu'un Id vaut 0, l'objet est affiché « Bientôt » dans la boutique.
--
-- Coming = true : l'effet n'est pas encore codé (prochaine version). L'objet
-- reste affiché « Bientôt » même avec un Id, pour ne jamais vendre du vide.

local Monetization = {}

-- Game Passes : achetés une seule fois, effet permanent.
-- Category sert à ranger la boutique. Requires = autre pass nécessaire avant.
Monetization.GamePasses = {
	-- 🪙 Gagner plus
	GoldX2 = { Id = 0, Category = "Or", Name = "Or x2", Description = "Double tout l'or que tu gagnes", Price = 199 },
	SuperGold = { Id = 0, Category = "Or", Name = "Super Or x2", Description = "Encore x2 ! Cumulable avec Or x2 (x4 au total)", Price = 699 },
	OfflinePlus = { Id = 0, Category = "Or", Name = "Gains hors ligne +", Description = "Tes dragons produisent 24 h à 100 % quand tu es absent", Price = 149 },
	ClickX3 = { Id = 0, Category = "Or", Name = "Récolte x3", Description = "Chaque clic sur « Récolter » rapporte 3 fois plus", Price = 79 },

	-- 🍀 Plus de chance
	LuckX2 = { Id = 0, Category = "Chance", Name = "Chance x2", Description = "Mutations 2 fois plus fréquentes", Price = 299 },
	SuperLuck = { Id = 0, Category = "Chance", Name = "Super Chance x2", Description = "Encore x2 ! Cumulable avec Chance x2 (x4 au total)", Price = 899 },
	LegendHunter = { Id = 0, Category = "Chance", Name = "Chasseur de Légendaires", Description = "+50 % de chance d'avoir un Légendaire", Price = 499 },
	LuckyFusion = { Id = 0, Category = "Chance", Name = "Fusion chanceuse", Description = "6 % de chance d'améliorer la mutation en fusionnant (au lieu de 2 %)", Price = 349 },

	-- ⚡ Aller plus vite
	TripleHatch = { Id = 0, Category = "Vitesse", Name = "Triple éclosion", Description = "Ouvre 3 œufs d'un coup", Price = 149 },
	OctoHatch = { Id = 0, Category = "Vitesse", Name = "Octuple éclosion", Description = "Ouvre 8 œufs d'un coup", Price = 599, Requires = "TripleHatch" },
	AutoHatch = { Id = 0, Category = "Vitesse", Name = "Éclosion automatique", Description = "Ouvre des œufs tout seul quand tu es près d'un œuf", Price = 399 },
	AutoFusion = { Id = 0, Category = "Vitesse", Name = "Fusion automatique", Description = "Tes dragons fusionnent tout seuls", Price = 249 },
	FastHatch = { Id = 0, Category = "Vitesse", Name = "Éclosion rapide", Description = "Animation d'éclosion 3 fois plus rapide", Price = 79 },
	Speed = { Id = 0, Category = "Vitesse", Name = "Vitesse x2", Description = "Cours 2 fois plus vite", Price = 99 },
	Teleport = { Id = 0, Category = "Vitesse", Name = "Téléporteur", Description = "Va dans n'importe quelle zone débloquée en un clic", Price = 129 },

	-- 🏠 Plus de place
	BigNest = { Id = 0, Category = "Nid", Name = "Grand nid", Description = "+10 places pour tes dragons", Price = 99 },
	GiantNest = { Id = 0, Category = "Nid", Name = "Nid géant", Description = "+25 places pour tes dragons", Price = 399, Requires = "BigNest" },
	Followers3 = { Id = 0, Category = "Nid", Name = "Escorte de dragons", Description = "3 dragons volent derrière toi au lieu d'un", Price = 199 },

	-- 😎 Se montrer
	VIP = { Id = 0, Category = "Style", Name = "👑 VIP", Description = "Titre VIP doré au-dessus de ta tête et dans le chat, +10 % d'or", Price = 399 },
	Aura = { Id = 0, Category = "Style", Name = "Aura de dragon", Description = "Des flammes magiques tournent autour de toi", Price = 149 },
	Wings = { Id = 0, Category = "Style", Name = "Ailes de dragon", Description = "Des ailes de dragon dans ton dos", Price = 249, Coming = true },

	-- ⚔ Arène (version 3)
	Trainer = { Id = 0, Category = "Arène", Name = "Entraîneur", Description = "+15 % de puissance dans l'Arène", Price = 349, Coming = true },
	DoubleEntry = { Id = 0, Category = "Arène", Name = "Double inscription", Description = "Inscris 2 dragons au tournoi", Price = 249, Coming = true },
}

Monetization.Categories = { "Or", "Chance", "Vitesse", "Nid", "Style", "Arène" }
Monetization.CategoryTitles = {
	["Or"] = "🪙 Gagner plus",
	["Chance"] = "🍀 Plus de chance",
	["Vitesse"] = "⚡ Aller plus vite",
	["Nid"] = "🏠 Plus de place",
	["Style"] = "😎 Se montrer",
	["Arène"] = "⚔ Arène",
}

-- Developer Products : achetables autant de fois que le joueur veut.
-- GoldMinutes = minutes de production données d'un coup (au moins MinGold).
Monetization.Products = {
	StarterPack = {
		Id = 0,
		Name = "🎒 Pack du débutant",
		Description = "Chance x3 pendant 1 h + 10 000 🪙. Une seule fois !",
		Price = 49,
		OneTime = true,
		Gold = 10000,
		Potion = { Kind = "Luck", Minutes = 60 },
	},
	LuckPotion = {
		Id = 0,
		Name = "🧪 Potion de chance x3",
		Description = "Mutations 3 fois plus fréquentes pendant 15 min",
		Price = 49,
		Potion = { Kind = "Luck", Minutes = 15 },
	},
	GoldPotion = {
		Id = 0,
		Name = "🧪 Potion d'or x3",
		Description = "3 fois plus d'or pendant 15 min",
		Price = 49,
		Potion = { Kind = "Gold", Minutes = 15 },
	},
	GoldSmall = { Id = 0, Name = "🪙 Petit sac d'or", Description = "15 minutes de production d'un coup", Price = 25, GoldMinutes = 15, MinGold = 2000 },
	GoldMedium = { Id = 0, Name = "💰 Sac d'or", Description = "1 heure de production d'un coup", Price = 99, GoldMinutes = 60, MinGold = 10000 },
	GoldHuge = { Id = 0, Name = "🏦 Coffre d'or", Description = "6 heures de production d'un coup", Price = 399, GoldMinutes = 360, MinGold = 75000 },
	UnlockZone = {
		Id = 0,
		Name = "🔓 Débloquer la zone suivante",
		Description = "Débloque tout de suite la prochaine zone",
		Price = 149,
		UnlockNextZone = true,
	},
	-- Version 2
	RoyalEgg = { Id = 0, Name = "🐲 Œuf Royal", Description = "Des dragons exclusifs, impossibles à avoir autrement", Price = 79, Coming = true },
	CosmicEgg = { Id = 0, Name = "🌌 Œuf Cosmique", Description = "1 chance sur 100 d'avoir un dragon Cosmique", Price = 199, Coming = true },
	MeteorShower = { Id = 0, Name = "☄ Pluie de météores", Description = "Déclenche une pluie d'œufs pour tout le serveur", Price = 99, Coming = true },
}
Monetization.ProductOrder = {
	"StarterPack", "LuckPotion", "GoldPotion", "GoldSmall", "GoldMedium", "GoldHuge",
	"UnlockZone", "RoyalEgg", "CosmicEgg", "MeteorShower",
}

-- En Studio, ces Game Passes sont considérés comme achetés, pour pouvoir
-- tester leur effet. Exemple : { "GoldX2", "TripleHatch" }
-- (n'a aucun effet sur le vrai jeu publié)
Monetization.StudioTestPasses = {}

function Monetization.IsSellable(item): boolean
	return item.Id ~= 0 and not item.Coming
end

function Monetization.FindProductById(id: number)
	for key, product in Monetization.Products do
		if product.Id == id and id ~= 0 then
			return key, product
		end
	end
	return nil, nil
end

return Monetization
