-- Fenêtre « Quêtes » : récompense de connexion quotidienne et quêtes du jour.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Quests = require(Shared.Quests)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)

local QuestMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

QuestMenu.Frame = nil :: Frame?

local list: ScrollingFrame
local menuButton: TextButton

local function today(): number
	return Quests.Today(workspace:GetServerTimeNow())
end

local function dailyAvailable(data): boolean
	return data.LastDailyDay < today()
end

local function card(order: number, height: number)
	return make("Frame", {
		Size = UDim2.new(1, -8, 0, height),
		BackgroundColor3 = COLORS.PanelLight,
		LayoutOrder = order,
		Parent = list,
	}, { UI.corner(8) })
end

local function buildDaily(data)
	local available = dailyAvailable(data)
	local streak = if available then Quests.NextStreak(data.LastDailyDay, data.DailyStreak, today()) else data.DailyStreak
	local current = (streak - 1) % #Quests.DailyRewards + 1

	local frame = card(1, 132)
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -20, 0, 22), Text = "🎁 Récompense du jour", Parent = frame })

	local row = make("Frame", {
		Position = UDim2.fromOffset(10, 34),
		Size = UDim2.new(1, -20, 0, 46),
		BackgroundTransparency = 1,
		Parent = frame,
	}, { make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	for day, reward in Quests.DailyRewards do
		local done = day < current or (day == current and not available)
		local cell = make("Frame", {
			Size = UDim2.new(1 / #Quests.DailyRewards, -4, 1, 0),
			BackgroundColor3 = if done then COLORS.Success elseif day == current then COLORS.Gold else COLORS.Panel,
			LayoutOrder = day,
			Parent = row,
		}, { UI.corner(6) })
		label({
			Size = UDim2.fromScale(1, 0.45),
			Text = `J{day}`,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if day == current and not done then COLORS.Panel else COLORS.Text,
			Parent = cell,
		})
		label({
			Position = UDim2.fromScale(0, 0.45),
			Size = UDim2.fromScale(1, 0.55),
			Text = if reward.Spins then `🎲{reward.Spins}` else `{reward.Gold}`,
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.Gotham,
			TextColor3 = if day == current and not done then COLORS.Panel else COLORS.Text,
			Parent = cell,
		})
	end

	local claim = button({
		Position = UDim2.new(0, 10, 0, 88),
		Size = UDim2.new(1, -20, 0, 36),
		Text = if available
			then `Réclamer : {Quests.RewardText(Quests.DailyRewardFor(streak))}`
			else "✔ Reçue, reviens demain !",
		AutoButtonColor = available,
		Parent = frame,
	}, if available then COLORS.Success else COLORS.Panel)
	if available then
		claim.Activated:Connect(function()
			Remotes.Quest:FireServer("Daily")
		end)
	end
end

local function buildQuest(index: number, quest)
	local def = Quests.Pool[quest.Id]
	if not def then
		return
	end
	local done = quest.Progress >= def.Goal

	local frame = card(index + 1, 76)
	label({ Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -130, 0, 22), Text = def.Text, Parent = frame })
	label({
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, -130, 0, 16),
		Text = Quests.RewardText(def),
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.Gold,
		Parent = frame,
	})
	local fill, text = UI.bar(frame, UDim2.fromOffset(10, 52), UDim2.new(1, -130, 0, 14), COLORS.XP)
	fill.Size = UDim2.fromScale(math.clamp(quest.Progress / def.Goal, 0, 1), 1)
	text.Text = `{UI.formatNumber(quest.Progress)} / {UI.formatNumber(def.Goal)}`

	local canClaim = done and not quest.Claimed
	local claim = button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(100, 40),
		Text = if quest.Claimed then "✔" elseif done then "Réclamer" else "En cours",
		AutoButtonColor = canClaim,
		Parent = frame,
	}, if canClaim then COLORS.Success else COLORS.Panel)
	if canClaim then
		claim.Activated:Connect(function()
			Remotes.Quest:FireServer("Claim", index)
		end)
	end
end

local function hasSomethingToClaim(data): boolean
	if dailyAvailable(data) then
		return true
	end
	for _, quest in data.Quests do
		local def = Quests.Pool[quest.Id]
		if def and quest.Progress >= def.Goal and not quest.Claimed then
			return true
		end
	end
	return false
end

local function refresh()
	local data = State.Data
	if not data then
		return
	end
	menuButton.Text = if hasSomethingToClaim(data) then "📜 Quêtes ❗" else "📜 Quêtes"

	local frame = QuestMenu.Frame :: Frame
	if not frame.Visible then
		return -- on reconstruit seulement quand la fenêtre est ouverte
	end
	UI.clear(list)
	buildDaily(data)
	for index, quest in data.Quests do
		buildQuest(index, quest)
	end
	label({
		Size = UDim2.new(1, -8, 0, 18),
		Text = "Nouvelles quêtes chaque jour à minuit (UTC)",
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.Gotham,
		TextColor3 = COLORS.Muted,
		LayoutOrder = 100,
		Parent = list,
	})
end

function QuestMenu.Build(gui: ScreenGui, questButton: TextButton)
	menuButton = questButton
	local frame
	frame, list = UI.panel(gui, "📜 Quêtes du jour", COLORS.Gold)
	QuestMenu.Frame = frame

	State.DataChanged:Connect(refresh)
	UI.PanelOpened:Connect(function(opened)
		if opened == frame then
			refresh()
		end
	end)
	refresh()

	-- Le jour peut changer pendant que le joueur est connecté
	task.spawn(function()
		while true do
			task.wait(30)
			refresh()
		end
	end)
end

return QuestMenu
