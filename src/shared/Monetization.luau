-- Tout ce qui rapporte des Robux.
--
-- Remplace chaque Id = 0 par l'ID que Roblox te donne quand tu crées le
-- Game Pass ou le Developer Product (voir README, étape "Monétisation").
-- Tant qu'un Id vaut 0, l'objet est affiché comme "Bientôt" dans la boutique.

local Monetization = {}

-- Game Passes : achetés une seule fois, avantage permanent
Monetization.GamePasses = {
	VIP = {
		Id = 0,
		Name = "VIP",
		Description = "x2 Yens sur chaque combat",
		Price = 199,
	},
	DoubleXP = {
		Id = 0,
		Name = "XP x2",
		Description = "Monte de niveau deux fois plus vite",
		Price = 249,
	},
}
Monetization.GamePassOrder = { "VIP", "DoubleXP" }

-- Developer Products : achetables autant de fois que le joueur veut
Monetization.Products = {
	Spins5 = {
		Id = 0,
		Name = "5 Spins",
		Description = "5 tirages de style",
		Price = 49,
		Spins = 5,
	},
	Spins25 = {
		Id = 0,
		Name = "25 Spins",
		Description = "25 tirages (meilleure offre !)",
		Price = 199,
		Spins = 25,
	},
	Yen5000 = {
		Id = 0,
		Name = "5 000 Yens",
		Description = "Un paquet de Yens",
		Price = 99,
		Yen = 5000,
	},
}
Monetization.ProductOrder = { "Spins5", "Spins25", "Yen5000" }

function Monetization.FindProductById(id: number)
	for key, product in Monetization.Products do
		if product.Id == id and id ~= 0 then
			return key, product
		end
	end
	return nil, nil
end

return Monetization
