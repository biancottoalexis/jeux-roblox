-- Les zones du jeu. Chaque zone a un œuf, un prix pour la débloquer et un
-- style (couleur et matière du sol) utilisé par la carte générée en code.

local Zones = {}

Zones.List = {
	{
		Id = "Prairie",
		DisplayName = "🌿 Prairie",
		UnlockPrice = 0,
		EggName = "Œuf des Prés",
		EggPrice = 50,
		Ground = Color3.fromRGB(100, 180, 80),
		Material = Enum.Material.Grass,
		EggColor = Color3.fromRGB(170, 230, 120),
	},
	{
		Id = "Volcan",
		DisplayName = "🌋 Volcan",
		UnlockPrice = 2500,
		EggName = "Œuf de Braise",
		EggPrice = 5000,
		Ground = Color3.fromRGB(70, 50, 45),
		Material = Enum.Material.Basalt,
		EggColor = Color3.fromRGB(255, 110, 40),
	},
	{
		Id = "Ocean",
		DisplayName = "🌊 Océan glacé",
		UnlockPrice = 75000,
		EggName = "Œuf des Glaces",
		EggPrice = 150000,
		Ground = Color3.fromRGB(190, 225, 245),
		Material = Enum.Material.Glacier,
		EggColor = Color3.fromRGB(110, 190, 255),
	},
	{
		Id = "Ciel",
		DisplayName = "⚡ Royaume du Ciel",
		UnlockPrice = 2500000,
		EggName = "Œuf des Tempêtes",
		EggPrice = 5000000,
		Ground = Color3.fromRGB(245, 245, 255),
		Material = Enum.Material.Snow,
		EggColor = Color3.fromRGB(255, 230, 90),
	},
	{
		Id = "Neant",
		DisplayName = "🌌 Néant cosmique",
		UnlockPrice = 100000000,
		EggName = "Œuf Cosmique",
		EggPrice = 200000000,
		Ground = Color3.fromRGB(35, 25, 70),
		Material = Enum.Material.Slate,
		EggColor = Color3.fromRGB(160, 90, 255),
	},
}

-- Taille de la carte générée en code
Zones.IslandSize = 140
Zones.Spacing = 180 -- distance entre le centre de deux îles

function Zones.Center(index: number): Vector3
	return Vector3.new((index - 1) * Zones.Spacing, 0, 0)
end

function Zones.Get(index: number)
	return Zones.List[index]
end

return Zones
