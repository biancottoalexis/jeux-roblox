-- Les grimoires que les joueurs reçoivent par tirage ("spin").
-- Chaque grimoire donne un attribut magique et 4 sorts (touches Z, X, C, V).
-- Chaque sort consomme du mana (ManaCost).
--
-- Types de sorts (Kind) disponibles :
--   Projectile : une boule qui avance et explose au contact
--   Nova       : une explosion autour du joueur
--   DashStrike : le joueur fonce et frappe tout sur son passage
--   Beam       : un rayon droit devant le joueur
--   Barrage    : plusieurs coups rapides devant le joueur

local Grimoires = {}

Grimoires.Rarities = {
	Commun = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 160, 255),
	Epique = Color3.fromRGB(190, 90, 255),
	Legendaire = Color3.fromRGB(255, 200, 40),
}

Grimoires.List = {
	Feu = {
		DisplayName = "Magie de Feu",
		Rarity = "Commun",
		Weight = 25,
		Color = Color3.fromRGB(255, 110, 30),
		Skills = {
			{ Name = "Boule de feu", Kind = "Projectile", Damage = 14, ManaCost = 15, Cooldown = 4, Speed = 90, Range = 80, Radius = 4, Stun = 0.4 },
			{ Name = "Explosion ardente", Kind = "Nova", Damage = 18, ManaCost = 25, Cooldown = 8, Radius = 14, Stun = 0.8, Knockback = 40 },
			{ Name = "Charge infernale", Kind = "DashStrike", Damage = 16, ManaCost = 20, Cooldown = 7, Distance = 30, Stun = 0.6 },
			{ Name = "Lance de flammes", Kind = "Beam", Damage = 28, ManaCost = 40, Cooldown = 14, Range = 60, Width = 6, Stun = 1.0, Knockback = 30 },
		},
	},
	Vent = {
		DisplayName = "Magie de Vent",
		Rarity = "Commun",
		Weight = 22,
		Color = Color3.fromRGB(150, 255, 190),
		Skills = {
			{ Name = "Lame de vent", Kind = "Projectile", Damage = 12, ManaCost = 12, Cooldown = 3, Speed = 120, Range = 90, Radius = 4, Stun = 0.3 },
			{ Name = "Rafale tranchante", Kind = "Barrage", Damage = 4, Hits = 5, Interval = 0.12, ManaCost = 20, Cooldown = 7, Stun = 0.3 },
			{ Name = "Tornade", Kind = "Nova", Damage = 16, ManaCost = 25, Cooldown = 9, Radius = 16, Stun = 0.8, Knockback = 60 },
			{ Name = "Ouragan", Kind = "Beam", Damage = 26, ManaCost = 40, Cooldown = 14, Range = 70, Width = 8, Stun = 0.8, Knockback = 50 },
		},
	},
	Eau = {
		DisplayName = "Magie d'Eau",
		Rarity = "Commun",
		Weight = 20,
		Color = Color3.fromRGB(50, 140, 255),
		Skills = {
			{ Name = "Bulle d'eau", Kind = "Projectile", Damage = 12, ManaCost = 12, Cooldown = 3, Speed = 80, Range = 80, Radius = 5, Stun = 0.5 },
			{ Name = "Prison aquatique", Kind = "Nova", Damage = 10, ManaCost = 25, Cooldown = 10, Radius = 12, Stun = 1.8 },
			{ Name = "Raz-de-marée", Kind = "Beam", Damage = 18, ManaCost = 25, Cooldown = 9, Range = 45, Width = 12, Stun = 0.6, Knockback = 45 },
			{ Name = "Dragon d'eau", Kind = "Projectile", Damage = 30, ManaCost = 40, Cooldown = 14, Speed = 70, Range = 100, Radius = 9, Stun = 1.0 },
		},
	},
	Foudre = {
		DisplayName = "Magie de Foudre",
		Rarity = "Rare",
		Weight = 12,
		Color = Color3.fromRGB(255, 240, 80),
		Skills = {
			{ Name = "Éclair", Kind = "Beam", Damage = 15, ManaCost = 15, Cooldown = 4, Range = 70, Width = 4, Stun = 0.5 },
			{ Name = "Pas de l'éclair", Kind = "DashStrike", Damage = 15, ManaCost = 18, Cooldown = 6, Distance = 40, Stun = 0.6 },
			{ Name = "Mille frappes", Kind = "Barrage", Damage = 5, Hits = 6, Interval = 0.1, ManaCost = 25, Cooldown = 8, Stun = 0.3 },
			{ Name = "Jugement céleste", Kind = "Nova", Damage = 32, ManaCost = 45, Cooldown = 16, Radius = 20, Stun = 1.2, Knockback = 45 },
		},
	},
	Glace = {
		DisplayName = "Magie de Glace",
		Rarity = "Rare",
		Weight = 10,
		Color = Color3.fromRGB(150, 225, 255),
		Skills = {
			{ Name = "Pic de glace", Kind = "Projectile", Damage = 13, ManaCost = 15, Cooldown = 4, Speed = 100, Range = 80, Radius = 4, Stun = 0.8 },
			{ Name = "Prison gelée", Kind = "Nova", Damage = 12, ManaCost = 30, Cooldown = 10, Radius = 14, Stun = 2.0 },
			{ Name = "Glissade givrée", Kind = "DashStrike", Damage = 14, ManaCost = 18, Cooldown = 6, Distance = 35, Stun = 0.8 },
			{ Name = "Hiver éternel", Kind = "Beam", Damage = 30, ManaCost = 45, Cooldown = 15, Range = 65, Width = 8, Stun = 1.5 },
		},
	},
	Lumiere = {
		DisplayName = "Magie de Lumière",
		Rarity = "Epique",
		Weight = 6,
		Color = Color3.fromRGB(255, 245, 190),
		Skills = {
			{ Name = "Épées de lumière", Kind = "Barrage", Damage = 5, Hits = 6, Interval = 0.08, ManaCost = 18, Cooldown = 5, Stun = 0.4 },
			{ Name = "Vitesse de la lumière", Kind = "DashStrike", Damage = 18, ManaCost = 18, Cooldown = 5, Distance = 55, Stun = 0.6 },
			{ Name = "Rayon sacré", Kind = "Beam", Damage = 24, ManaCost = 30, Cooldown = 9, Range = 90, Width = 5, Stun = 0.8 },
			{ Name = "Jugement lumineux", Kind = "Nova", Damage = 36, ManaCost = 50, Cooldown = 16, Radius = 22, Stun = 1.4, Knockback = 50 },
		},
	},
	Ombre = {
		DisplayName = "Magie d'Ombre",
		Rarity = "Epique",
		Weight = 4,
		Color = Color3.fromRGB(110, 40, 190),
		Skills = {
			{ Name = "Griffe d'ombre", Kind = "Barrage", Damage = 5, Hits = 5, Interval = 0.1, ManaCost = 18, Cooldown = 5, Stun = 0.4 },
			{ Name = "Passage spectral", Kind = "DashStrike", Damage = 20, ManaCost = 20, Cooldown = 6, Distance = 45, Stun = 0.8 },
			{ Name = "Orbe des ténèbres", Kind = "Projectile", Damage = 24, ManaCost = 30, Cooldown = 8, Speed = 70, Range = 90, Radius = 7, Stun = 1.0 },
			{ Name = "Éclipse", Kind = "Nova", Damage = 38, ManaCost = 50, Cooldown = 16, Radius = 22, Stun = 1.5, Knockback = 50 },
		},
	},
	-- Le grimoire ultra rare (1 %) : une magie qui annule toutes les autres.
	-- Ses sorts coûtent peu de mana car il compte sur la force physique.
	Neant = {
		DisplayName = "Grimoire du Néant",
		Rarity = "Legendaire",
		Weight = 1,
		Color = Color3.fromRGB(25, 25, 25),
		Skills = {
			{ Name = "Lame annulatrice", Kind = "Barrage", Damage = 7, Hits = 5, Interval = 0.1, ManaCost = 5, Cooldown = 4, Stun = 0.4 },
			{ Name = "Bond démoniaque", Kind = "DashStrike", Damage = 22, ManaCost = 5, Cooldown = 5, Distance = 50, Stun = 0.8 },
			{ Name = "Tranche du néant", Kind = "Beam", Damage = 30, ManaCost = 10, Cooldown = 9, Range = 75, Width = 6, Stun = 1.0, Knockback = 40 },
			{ Name = "Forme démoniaque", Kind = "Nova", Damage = 45, ManaCost = 15, Cooldown = 18, Radius = 24, Stun = 1.5, Knockback = 70 },
		},
	},
}

-- Ordre d'affichage
Grimoires.Order = { "Feu", "Vent", "Eau", "Foudre", "Glace", "Lumiere", "Ombre", "Neant" }

-- Tire un grimoire au hasard selon les poids (Weight)
function Grimoires.Roll(rng: Random?): string
	local random = rng or Random.new()
	local total = 0
	for _, id in Grimoires.Order do
		total += Grimoires.List[id].Weight
	end
	local pick = random:NextNumber() * total
	for _, id in Grimoires.Order do
		pick -= Grimoires.List[id].Weight
		if pick <= 0 then
			return id
		end
	end
	return Grimoires.Order[1]
end

return Grimoires
