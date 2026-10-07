-- Réglages généraux du jeu. Modifie les valeurs ici pour équilibrer le combat
-- sans toucher au reste du code.

local Config = {}

Config.Combat = {
	-- Attaques de base (clic gauche)
	M1Damage = 6,
	M1FinalDamage = 10, -- dégâts du dernier coup du combo
	M1ComboLength = 4,
	M1Interval = 0.35, -- délai minimum entre deux coups
	M1ComboReset = 1.2, -- le combo repart à 1 après ce délai sans frapper
	M1EndLag = 1.0, -- pause après le dernier coup du combo
	M1HitboxSize = Vector3.new(5, 5, 6),
	M1Stun = 0.6,
	FinalKnockback = 55,

	-- Garde (touche F)
	BlockDamageReduction = 0.8, -- 80 % des dégâts bloqués
	BlockAngle = 0.3, -- il faut faire face à l'attaquant pour bloquer
	BlockWalkSpeed = 8,

	-- Esquive (touche Q)
	DashCooldown = 1.5,
	DashSpeed = 70,
	DashDuration = 0.2,

	-- Divers
	DefaultWalkSpeed = 16,
	StunWalkSpeed = 4,
	LastAttackerWindow = 15, -- secondes pendant lesquelles un kill est attribué
}

-- Mana : chaque sort en consomme, il se recharge avec le temps
Config.Mana = {
	Base = 100, -- mana max au niveau 1
	PerLevel = 3, -- mana max gagné par niveau
	RegenPerSecond = 6,
	PerM1Hit = 3, -- mana récupéré à chaque coup de poing qui touche
}

Config.Progression = {
	KillGold = 50,
	KillXP = 40,
	DummyGold = 5,
	DummyXP = 10,
	StartingSpins = 3,
	MaxLevel = 200,
	-- Niveau requis pour débloquer chaque sort (Z, X, C, V)
	SkillUnlockLevels = { 1, 5, 15, 30 },
}

function Config.XPForLevel(level: number): number
	return math.floor(100 * level ^ 1.4)
end

Config.Data = {
	StoreName = "PlayerData_v1",
	AutosaveInterval = 120,
}

Config.Dummies = {
	RespawnTime = 5,
	Positions = {
		Vector3.new(25, 5, 0),
		Vector3.new(25, 5, 12),
		Vector3.new(25, 5, -12),
	},
}

-- IDs d'animations (ex : "rbxassetid://123456"). Laisse vide tant que tu
-- n'as pas créé tes animations : le jeu fonctionne sans.
Config.Animations = {
	M1 = { "", "", "", "" },
	Block = "",
	Dash = "",
	Skill = "",
}

return Config
