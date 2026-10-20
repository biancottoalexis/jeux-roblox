-- Les ordres de chevaliers-mages : des équipes que les joueurs rejoignent.
-- Chaque ordre donne un petit bonus et gagne des points de mérite grâce à
-- ses membres (kills, quêtes, boss). Le classement des ordres est mondial.
--
-- Bonus disponibles (Bonus.Type) :
--   Damage    : dégâts en plus (0.05 = +5 %)
--   Gold      : or en plus
--   XP        : XP en plus
--   ManaRegen : recharge du mana plus rapide
--   MaxMana   : mana max en plus
--   MaxHealth : vie max en plus

local Orders = {}

Orders.List = {
	LoupEcarlate = {
		DisplayName = "Ordre du Loup Écarlate",
		Motto = "Frapper fort, frapper le premier.",
		Color = Color3.fromRGB(220, 50, 50),
		TeamColor = BrickColor.new("Really red"),
		Bonus = { Type = "Damage", Value = 0.05 },
		BonusText = "+5 % de dégâts",
	},
	AigleAzur = {
		DisplayName = "Ordre de l'Aigle d'Azur",
		Motto = "Le ciel n'a pas de limite.",
		Color = Color3.fromRGB(50, 120, 255),
		TeamColor = BrickColor.new("Really blue"),
		Bonus = { Type = "ManaRegen", Value = 0.2 },
		BonusText = "+20 % de recharge de mana",
	},
	LionDor = {
		DisplayName = "Ordre du Lion d'Or",
		Motto = "La gloire et la fortune.",
		Color = Color3.fromRGB(255, 200, 40),
		TeamColor = BrickColor.new("New Yeller"),
		Bonus = { Type = "Gold", Value = 0.15 },
		BonusText = "+15 % d'or",
	},
	CerfEmeraude = {
		DisplayName = "Ordre du Cerf d'Émeraude",
		Motto = "Tenir debout, quoi qu'il arrive.",
		Color = Color3.fromRGB(60, 200, 90),
		TeamColor = BrickColor.new("Lime green"),
		Bonus = { Type = "MaxHealth", Value = 0.1 },
		BonusText = "+10 % de vie max",
	},
	CorbeauNoir = {
		DisplayName = "Ordre du Corbeau Noir",
		Motto = "Apprendre dans l'ombre.",
		Color = Color3.fromRGB(130, 60, 200),
		TeamColor = BrickColor.new("Royal purple"),
		Bonus = { Type = "XP", Value = 0.15 },
		BonusText = "+15 % d'XP",
	},
	LicorneArgent = {
		DisplayName = "Ordre de la Licorne d'Argent",
		Motto = "Une magie sans fin.",
		Color = Color3.fromRGB(225, 230, 240),
		TeamColor = BrickColor.new("Institutional white"),
		Bonus = { Type = "MaxMana", Value = 0.15 },
		BonusText = "+15 % de mana max",
	},
}

-- Ordre d'affichage
Orders.Order = { "LoupEcarlate", "AigleAzur", "LionDor", "CerfEmeraude", "CorbeauNoir", "LicorneArgent" }

-- Valeur du bonus d'un ordre pour un type donné (0 si l'ordre n'a pas ce bonus)
function Orders.BonusFor(orderId: string?, bonusType: string): number
	local order = orderId and Orders.List[orderId]
	if order and order.Bonus.Type == bonusType then
		return order.Bonus.Value
	end
	return 0
end

return Orders
