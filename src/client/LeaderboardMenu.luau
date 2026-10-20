-- Fenêtre « Classement » : meilleurs joueurs (niveau, kills) et ordres.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Orders = require(Shared.Orders)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)

local LeaderboardMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

LeaderboardMenu.Frame = nil :: Frame?

local TABS = {
	{ Key = "Level", Title = "Niveau" },
	{ Key = "Kills", Title = "Kills" },
	{ Key = "Orders", Title = "Ordres" },
}
local MEDALS = { "🥇", "🥈", "🥉" }

local list: ScrollingFrame
local tabButtons: { [string]: TextButton } = {}
local currentTab = "Level"
local latest = nil

local function row(rank: number, name: string, value: number, color: Color3?)
	local isMe = name == Players.LocalPlayer.DisplayName
	local frame = make("Frame", {
		Size = UDim2.new(1, -8, 0, 34),
		BackgroundColor3 = if isMe then Color3.fromRGB(60, 60, 90) else COLORS.PanelLight,
		LayoutOrder = rank,
		Parent = list,
	}, { UI.corner(6) })
	label({
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.fromOffset(36, 22),
		Text = MEDALS[rank] or `{rank}.`,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	label({
		Position = UDim2.fromOffset(50, 6),
		Size = UDim2.new(1, -150, 0, 22),
		Text = name,
		TextColor3 = color or COLORS.Text,
		Parent = frame,
	})
	label({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 6),
		Size = UDim2.fromOffset(90, 22),
		Text = UI.formatNumber(value),
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = COLORS.Gold,
		Parent = frame,
	})
end

local function render()
	UI.clear(list)
	for key, tabButton in tabButtons do
		tabButton.BackgroundColor3 = if key == currentTab then COLORS.Accent else COLORS.PanelLight
	end

	if not latest then
		label({ Size = UDim2.new(1, -8, 0, 24), Text = "Chargement...", TextXAlignment = Enum.TextXAlignment.Center, Parent = list })
		return
	end

	local entries = latest[currentTab] or {}
	if #entries == 0 then
		label({ Size = UDim2.new(1, -8, 0, 24), Text = "Pas encore de classement", TextXAlignment = Enum.TextXAlignment.Center, Parent = list })
		return
	end
	for rank, entry in entries do
		if currentTab == "Orders" then
			local order = Orders.List[entry.Id]
			if order then
				row(rank, order.DisplayName, entry.Value, order.Color)
			end
		else
			row(rank, entry.Name, entry.Value)
		end
	end
end

function LeaderboardMenu.Build(gui: ScreenGui)
	local frame, content = UI.panel(gui, "🏆 Classement mondial", Color3.fromRGB(40, 150, 110))
	LeaderboardMenu.Frame = frame

	-- Onglets au-dessus de la liste
	local tabs = make("Frame", {
		Size = UDim2.new(1, -8, 0, 36),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = content,
	}, { make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })
	for index, tab in TABS do
		local tabButton = button({
			Size = UDim2.new(1 / #TABS, -6, 1, 0),
			Text = tab.Title,
			LayoutOrder = index,
			Parent = tabs,
		}, COLORS.PanelLight)
		tabButton.Activated:Connect(function()
			currentTab = tab.Key
			render()
		end)
		tabButtons[tab.Key] = tabButton
	end

	list = make("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = content,
	}, { make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

	Remotes.Leaderboard.OnClientEvent:Connect(function(data)
		latest = data
		render()
	end)

	UI.PanelOpened:Connect(function(opened)
		if opened == frame then
			Remotes.Leaderboard:FireServer()
			render()
		end
	end)

	-- Mise à jour tant que la fenêtre est ouverte
	task.spawn(function()
		while true do
			task.wait(30)
			if frame.Visible then
				Remotes.Leaderboard:FireServer()
			end
		end
	end)
end

return LeaderboardMenu
