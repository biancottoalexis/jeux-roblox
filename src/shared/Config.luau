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

-- Le boss : un démon qui apparaît régulièrement. Tous les joueurs peuvent
-- l'attaquer ensemble. Plus il y a de joueurs, plus il a de vie.
Config.Boss = {
	DisplayName = "Démon des Abysses",
	FirstSpawnDelay = 180, -- secondes avant le premier boss après l'ouverture du serveur
	Interval = 1800, -- 30 minutes entre deux boss
	Lifetime = 600, -- s'il n'est pas vaincu en 10 minutes, il s'enfuit
	SpawnPosition = Vector3.new(-70, 8, 0),
	Scale = 3, -- taille (3 = trois fois plus grand qu'un joueur)
	BaseHealth = 2500,
	HealthPerPlayer = 1500,
	WalkSpeed = 14,
	AggroRange = 150, -- distance à laquelle il repère les joueurs
	LeashRange = 120, -- il ne s'éloigne pas plus loin de son point d'apparition

	-- Coup de griffe quand un joueur est tout près
	SlashDamage = 14,
	SlashRange = 12,
	SlashCooldown = 1.6,

	-- Onde démoniaque : grosse explosion annoncée par un cercle rouge
	WaveDamage = 28,
	WaveRadius = 28,
	WaveCooldown = 9,
	WaveWarning = 1.2, -- temps pour s'enfuir après l'apparition du cercle

	-- Sous 50 % de vie, il devient enragé : plus rapide et attaque plus souvent
	EnrageAt = 0.5,
	EnrageSpeedMultiplier = 1.4,
	EnrageCooldownMultiplier = 0.6,

	-- Récompense de chaque participant (il faut avoir infligé au moins MinDamageShare des dégâts)
	RewardGold = 500,
	RewardXP = 600,
	MinDamageShare = 0.01,
	TopDamageSpins = 1, -- bonus pour le joueur qui a fait le plus de dégâts
}

-- Ordres de chevaliers-mages (voir Orders.luau pour les ordres eux-mêmes)
Config.Orders = {
	ChangeCost = 2000, -- or à payer pour changer d'ordre (le premier choix est gratuit)
	MinLevel = 3, -- niveau requis pour rejoindre un ordre
	-- Points de mérite rapportés à l'ordre
	MeritPerKill = 3,
	MeritPerQuest = 2,
	MeritPerBoss = 10,
	MeritPerDaily = 1,
	FlushInterval = 60, -- envoi des points au classement mondial (secondes)
}

-- Classement mondial
Config.Leaderboard = {
	Size = 10, -- nombre de joueurs affichés
	RefreshInterval = 120, -- mise à jour du classement (secondes)
	LevelStore = "Leaderboard_Level_v1",
	KillsStore = "Leaderboard_Kills_v1",
	OrderStore = "Leaderboard_Orders_v1",
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
