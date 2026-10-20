-- Récompense de connexion quotidienne et quêtes du jour.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Quests = require(Shared.Quests)
local Remotes = require(Shared.Remotes)

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local CombatService = require(script.Parent.CombatService)
local OrderService = require(script.Parent.OrderService)

local QuestService = {}

local rng = Random.new()

-- Tire de nouvelles quêtes si le jour a changé. Renvoie true si c'est le cas.
local function rollQuestsIfNewDay(data): boolean
	local today = Quests.Today()
	if data.Quests.Day == today then
		return false
	end

	local ids = {}
	for id in Quests.Pool do
		table.insert(ids, id)
	end
	table.sort(ids) -- même ordre de départ partout, puis mélange
	for i = #ids, 2, -1 do
		local j = rng:NextInteger(1, i)
		ids[i], ids[j] = ids[j], ids[i]
	end

	local list = {}
	for i = 1, math.min(Quests.PerDay, #ids) do
		table.insert(list, { Id = ids[i], Progress = 0, Claimed = false })
	end
	data.Quests = { Day = today, List = list }
	return true
end

local function checkNewDay(player: Player)
	local data = DataService.Get(player)
	if data and rollQuestsIfNewDay(data) then
		DataService.Update(player, function() end) -- renvoie les nouvelles quêtes au client
	end
end

-- Fait avancer les quêtes d'un type donné (voir Quests.luau)
function QuestService.Progress(player: Player, kind: string, amount: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	rollQuestsIfNewDay(data)

	local completed = {}
	local changed = false
	for _, quest in data.Quests.List do
		local def = Quests.Pool[quest.Id]
		if def and def.Kind == kind and not quest.Claimed and quest.Progress < def.Goal then
			quest.Progress = math.min(def.Goal, quest.Progress + amount)
			changed = true
			if quest.Progress >= def.Goal then
				table.insert(completed, def.Text)
			end
		end
	end

	if changed then
		DataService.Update(player, function() end)
	end
	for _, text in completed do
		Remotes.Notify:FireClient(player, `✅ Quête terminée : {text} ! Réclame ta récompense.`)
	end
end

local function claimQuest(player: Player, index: number)
	local data = DataService.Get(player)
	if not data then
		return
	end
	checkNewDay(player)
	local quest = data.Quests.List[index]
	local def = quest and Quests.Pool[quest.Id]
	if not quest or not def or quest.Claimed or quest.Progress < def.Goal then
		return
	end

	quest.Claimed = true
	ProgressionService.AddRewards(player, def.Gold or 0, def.XP or 0, def.Spins)
	OrderService.AddMerit(player, Config.Orders.MeritPerQuest)
	Remotes.Notify:FireClient(player, `Récompense reçue : {Quests.RewardText(def)}`)
end

local function claimDaily(player: Player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local today = Quests.Today()
	if data.LastDailyDay >= today then
		return -- déjà réclamée aujourd'hui
	end

	local streak = Quests.NextStreak(data.LastDailyDay, data.DailyStreak, today)
	local reward = Quests.DailyRewardFor(streak)
	DataService.Update(player, function(d)
		d.LastDailyDay = today
		d.DailyStreak = streak
	end)
	ProgressionService.AddRewards(player, reward.Gold or 0, 0, reward.Spins)
	OrderService.AddMerit(player, Config.Orders.MeritPerDaily)
	Remotes.Notify:FireClient(player, `🎁 Jour {streak} : {Quests.RewardText(reward)}`)
end

local function onQuestRequest(player: Player, action: unknown, arg: unknown)
	if action == "Daily" then
		claimDaily(player)
	elseif action == "Claim" and typeof(arg) == "number" and arg == math.floor(arg) and arg >= 1 and arg <= Quests.PerDay then
		claimQuest(player, arg)
	end
end

function QuestService.Init() end

function QuestService.Start()
	Remotes.Quest.OnServerEvent:Connect(onQuestRequest)

	CombatService.Killed:Connect(function(killer: Player, kind: string)
		QuestService.Progress(killer, if kind == "Dummy" then "Dummy" else "Kill", 1)
	end)
	CombatService.SkillUsed:Connect(function(player: Player)
		QuestService.Progress(player, "Skill", 1)
	end)
	CombatService.DamageDealt:Connect(function(player: Player, target: Humanoid, amount: number)
		QuestService.Progress(player, "Damage", amount)
		if target.Parent and target.Parent:GetAttribute("IsBoss") then
			QuestService.Progress(player, "BossDamage", amount)
		end
	end)

	DataService.PlayerLoaded:Connect(function(player, data)
		checkNewDay(player)
		if data.LastDailyDay < Quests.Today() then
			task.delay(4, function()
				if player.Parent then
					Remotes.Notify:FireClient(player, "🎁 Ta récompense du jour t'attend ! Ouvre « 📜 Quêtes ».")
				end
			end)
		end
	end)

	-- Nouvelles quêtes à minuit pour les joueurs déjà connectés
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				task.spawn(checkNewDay, player)
			end
		end
	end)
end

return QuestService
