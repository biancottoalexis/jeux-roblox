-- Les styles de combat que les joueurs obtiennent en "spin".
-- Chaque style a 4 compétences (touches Z, X, C, V).
--
-- Types de compétences (Kind) disponibles :
--   Projectile : une boule qui avance et explose au contact
--   Nova       : une explosion autour du joueur
--   DashStrike : le joueur fonce et frappe tout sur son passage
--   Beam       : un rayon droit devant le joueur
--   Barrage    : plusieurs coups rapides devant le joueur

local Styles = {}

Styles.Rarities = {
	Commun = Color3.fromRGB(200, 200, 200),
	Rare = Color3.fromRGB(80, 160, 255),
	Epique = Color3.fromRGB(190, 90, 255),
	Legendaire = Color3.fromRGB(255, 200, 40),
}

Styles.List = {
	Flamme = {
		DisplayName = "Flamme",
		Rarity = "Commun",
		Weight = 35,
		Color = Color3.fromRGB(255, 120, 30),
		Skills = {
			{ Name = "Boule de feu", Kind = "Projectile", Damage = 14, Cooldown = 4, Speed = 90, Range = 80, Radius = 4, Stun = 0.4 },
			{ Name = "Explosion ardente", Kind = "Nova", Damage = 18, Cooldown = 8, Radius = 14, Stun = 0.8, Knockback = 40 },
			{ Name = "Charge infernale", Kind = "DashStrike", Damage = 16, Cooldown = 7, Distance = 30, Stun = 0.6 },
			{ Name = "Pilier de flammes", Kind = "Beam", Damage = 28, Cooldown = 14, Range = 60, Width = 6, Stun = 1.0, Knockback = 30 },
		},
	},
	Tempete = {
		DisplayName = "Tempête",
		Rarity = "Commun",
		Weight = 30,
		Color = Color3.fromRGB(150, 255, 200),
		Skills = {
			{ Name = "Lame de vent", Kind = "Projectile", Damage = 12, Cooldown = 3, Speed = 120, Range = 90, Radius = 4, Stun = 0.3 },
			{ Name = "Rafale", Kind = "Barrage", Damage = 4, Hits = 5, Interval = 0.12, Cooldown = 7, Stun = 0.3 },
			{ Name = "Tornade", Kind = "Nova", Damage = 16, Cooldown = 9, Radius = 16, Stun = 0.8, Knockback = 60 },
			{ Name = "Ouragan", Kind = "Beam", Damage = 26, Cooldown = 14, Range = 70, Width = 8, Stun = 0.8, Knockback = 50 },
		},
	},
	Foudre = {
		DisplayName = "Foudre",
		Rarity = "Rare",
		Weight = 15,
		Color = Color3.fromRGB(255, 240, 80),
		Skills = {
			{ Name = "Éclair", Kind = "Beam", Damage = 15, Cooldown = 4, Range = 70, Width = 4, Stun = 0.5 },
			{ Name = "Pas de l'éclair", Kind = "DashStrike", Damage = 15, Cooldown = 6, Distance = 40, Stun = 0.6 },
			{ Name = "Mille frappes", Kind = "Barrage", Damage = 5, Hits = 6, Interval = 0.1, Cooldown = 8, Stun = 0.3 },
			{ Name = "Jugement céleste", Kind = "Nova", Damage = 32, Cooldown = 16, Radius = 20, Stun = 1.2, Knockback = 45 },
		},
	},
	Glace = {
		DisplayName = "Glace",
		Rarity = "Rare",
		Weight = 12,
		Color = Color3.fromRGB(140, 220, 255),
		Skills = {
			{ Name = "Pic de glace", Kind = "Projectile", Damage = 13, Cooldown = 4, Speed = 100, Range = 80, Radius = 4, Stun = 0.8 },
			{ Name = "Prison gelée", Kind = "Nova", Damage = 12, Cooldown = 10, Radius = 14, Stun = 2.0 },
			{ Name = "Glissade", Kind = "DashStrike", Damage = 14, Cooldown = 6, Distance = 35, Stun = 0.8 },
			{ Name = "Hiver éternel", Kind = "Beam", Damage = 30, Cooldown = 15, Range = 65, Width = 8, Stun = 1.5 },
		},
	},
	Ombre = {
		DisplayName = "Ombre",
		Rarity = "Epique",
		Weight = 6,
		Color = Color3.fromRGB(120, 40, 200),
		Skills = {
			{ Name = "Griffe d'ombre", Kind = "Barrage", Damage = 5, Hits = 5, Interval = 0.1, Cooldown = 5, Stun = 0.4 },
			{ Name = "Passage spectral", Kind = "DashStrike", Damage = 20, Cooldown = 6, Distance = 45, Stun = 0.8 },
			{ Name = "Orbe du néant", Kind = "Projectile", Damage = 24, Cooldown = 8, Speed = 70, Range = 90, Radius = 7, Stun = 1.0 },
			{ Name = "Éclipse", Kind = "Nova", Damage = 38, Cooldown = 16, Radius = 22, Stun = 1.5, Knockback = 50 },
		},
	},
	Soleil = {
		DisplayName = "Soleil",
		Rarity = "Legendaire",
		Weight = 2,
		Color = Color3.fromRGB(255, 220, 120),
		Skills = {
			{ Name = "Rayon solaire", Kind = "Beam", Damage = 20, Cooldown = 4, Range = 80, Width = 5, Stun = 0.6 },
			{ Name = "Couronne ardente", Kind = "Nova", Damage = 24, Cooldown = 7, Radius = 18, Stun = 1.0, Knockback = 50 },
			{ Name = "Comète", Kind = "Projectile", Damage = 30, Cooldown = 9, Speed = 110, Range = 100, Radius = 8, Stun = 1.0 },
			{ Name = "Supernova", Kind = "Beam", Damage = 45, Cooldown = 18, Range = 100, Width = 12, Stun = 1.5, Knockback = 70 },
		},
	},
}

-- Ordre d'affichage
Styles.Order = { "Flamme", "Tempete", "Foudre", "Glace", "Ombre", "Soleil" }

-- Tire un style au hasard selon les poids (Weight)
function Styles.Roll(rng: Random?): string
	local random = rng or Random.new()
	local total = 0
	for _, id in Styles.Order do
		total += Styles.List[id].Weight
	end
	local pick = random:NextNumber() * total
	for _, id in Styles.Order do
		pick -= Styles.List[id].Weight
		if pick <= 0 then
			return id
		end
	end
	return Styles.Order[1]
end

return Styles
