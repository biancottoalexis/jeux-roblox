-- Récompense de connexion quotidienne et quêtes du jour.
-- Chaque jour (minuit UTC), le joueur reçoit de nouvelles quêtes tirées au
-- hasard dans Quests.Pool.
--
-- Types de quêtes (Kind) :
--   Dummy      : vaincre des mannequins
--   Kill       : vaincre des joueurs
--   Skill      : lancer des sorts
--   Damage     : infliger des dégâts (n'importe quelle cible)
--   BossDamage : infliger des dégâts au boss
--   Boss       : participer à la victoire contre un boss

local Quests = {}

-- Nombre de quêtes données chaque jour
Quests.PerDay = 3

-- Récompense de connexion : jour 1 à 7, puis on recommence au jour 1.
-- Il faut se connecter chaque jour pour avancer, sinon on repart au jour 1.
Quests.DailyRewards = {
	{ Gold = 100 },
	{ Gold = 200 },
	{ Gold = 300, Spins = 1 },
	{ Gold = 400 },
	{ Gold = 500 },
	{ Gold = 750, Spins = 1 },
	{ Gold = 1500, Spins = 3 },
}

Quests.Pool = {
	Dummy10 = { Text = "Bats 10 mannequins", Kind = "Dummy", Goal = 10, Gold = 150, XP = 120 },
	Dummy25 = { Text = "Bats 25 mannequins", Kind = "Dummy", Goal = 25, Gold = 350, XP = 300 },
	Kill3 = { Text = "Vaincs 3 joueurs", Kind = "Kill", Goal = 3, Gold = 300, XP = 250 },
	Kill10 = { Text = "Vaincs 10 joueurs", Kind = "Kill", Goal = 10, Gold = 800, XP = 600, Spins = 1 },
	Skill30 = { Text = "Lance 30 sorts", Kind = "Skill", Goal = 30, Gold = 200, XP = 150 },
	Damage2000 = { Text = "Inflige 2 000 dégâts", Kind = "Damage", Goal = 2000, Gold = 250, XP = 200 },
	BossDamage500 = { Text = "Inflige 500 dégâts au démon", Kind = "BossDamage", Goal = 500, Gold = 400, XP = 300 },
	Boss1 = { Text = "Participe à la victoire contre un démon", Kind = "Boss", Goal = 1, Gold = 600, XP = 500, Spins = 1 },
}

-- Numéro du jour (change à minuit UTC). Le client passe workspace:GetServerTimeNow()
-- pour être d'accord avec le serveur.
function Quests.Today(time: number?): number
	return math.floor((time or os.time()) / 86400)
end

-- Récompense quotidienne pour une série de connexions (1, 2, 3...)
function Quests.DailyRewardFor(streak: number)
	return Quests.DailyRewards[(streak - 1) % #Quests.DailyRewards + 1]
end

-- Série qu'aura le joueur s'il réclame aujourd'hui
function Quests.NextStreak(lastDay: number, streak: number, today: number): number
	if lastDay == today - 1 then
		return streak + 1
	end
	return 1
end

-- Texte court d'une récompense : "300 🪙 • 1 🎲"
function Quests.RewardText(reward): string
	local parts = {}
	if reward.Gold then
		table.insert(parts, `{reward.Gold} 🪙`)
	end
	if reward.XP then
		table.insert(parts, `{reward.XP} XP`)
	end
	if reward.Spins then
		table.insert(parts, `{reward.Spins} 🎲`)
	end
	return table.concat(parts, " • ")
end

return Quests
