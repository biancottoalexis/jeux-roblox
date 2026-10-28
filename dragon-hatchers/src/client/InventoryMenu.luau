-- Fenêtre « Mes dragons » : les dragons du nid regroupés (3 identiques =
-- fusion possible), agrandissement du nid et « Tout fusionner ».

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Dragons = require(Shared.Dragons)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)
local DragonView = require(script.Parent.DragonView)
local Purchase = require(script.Parent.Purchase)

local InventoryMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

InventoryMenu.Frame = nil :: Frame?

local grid: Frame
local nestLabel: TextLabel
local upgradeButton: TextButton
local fuseAllButton: TextButton

type Group = { Sample: any, Ids: { string }, Production: number }

-- Regroupe les dragons identiques, du plus productif au moins productif
function InventoryMenu.Groups(dragons: { any }): { Group }
	local byKey: { [string]: Group } = {}
	local list = {}
	for _, dragon in dragons do
		local key = Dragons.Key(dragon)
		local group = byKey[key]
		if not group then
			group = { Sample = dragon, Ids = {}, Production = Dragons.Production(dragon) }
			byKey[key] = group
			table.insert(list, group)
		end
		table.insert(group.Ids, dragon.Id)
	end
	table.sort(list, function(a, b)
		return a.Production > b.Production
	end)
	return list
end

function InventoryMenu.CanFuse(group: Group): boolean
	return #group.Ids >= Config.Fusion.Required and group.Sample.L < Config.Fusion.MaxLevel
end

local function card(order: number, group: Group)
	local dragon = group.Sample
	local def = Dragons.Species[dragon.S]
	local rarity = Dragons.Rarities[def.Rarity]
	local mutation = Dragons.Mutations[dragon.M]

	local frame = make("Frame", {
		BackgroundColor3 = COLORS.Card,
		LayoutOrder = order,
		Parent = grid,
	}, { UI.corner(14), UI.stroke(rarity.Color, 3) })

	DragonView.Create(dragon, {
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 0, 84),
		Parent = frame,
	})

	if #group.Ids > 1 then
		label({
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 4),
			Size = UDim2.fromOffset(40, 24),
			Text = `x{#group.Ids}`,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = COLORS.Gold,
			Parent = frame,
		})
	end
	if dragon.L > 1 then
		label({
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.fromOffset(50, 22),
			Text = `Niv. {dragon.L}`,
			Parent = frame,
		})
	end

	label({
		Position = UDim2.fromOffset(6, 92),
		Size = UDim2.new(1, -12, 0, 18),
		Text = def.DisplayName,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = frame,
	})
	label({
		Position = UDim2.fromOffset(6, 110),
		Size = UDim2.new(1, -12, 0, 15),
		Text = if mutation.DisplayName ~= "" then `{mutation.DisplayName} • {rarity.DisplayName}` else rarity.DisplayName,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = mutation.Color or rarity.Color,
		Parent = frame,
	})
	label({
		Position = UDim2.fromOffset(6, 126),
		Size = UDim2.new(1, -12, 0, 15),
		Text = `+{Format.Short(group.Production)} 🪙/s`,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = COLORS.Gold,
		Parent = frame,
	})

	if InventoryMenu.CanFuse(group) then
		local fuse = button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, -12, 0, 30),
			Text = "🔁 Fusionner",
			Parent = frame,
		}, COLORS.Green)
		fuse.Activated:Connect(function()
			Remotes.Fuse:FireServer(Dragons.Key(dragon))
		end)
	else
		-- Relâcher demande une confirmation (deuxième appui)
		local confirming = false
		local release = button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -6),
			Size = UDim2.new(1, -12, 0, 30),
			Text = "Relâcher",
			Parent = frame,
		}, COLORS.Gray)
		release.Activated:Connect(function()
			if confirming then
				Remotes.Release:FireServer(group.Ids[1])
				return
			end
			confirming = true
			release.Text = "Sûr ?"
			UI.setButtonColor(release, COLORS.Red)
			task.delay(2.5, function()
				if release.Parent then
					confirming = false
					release.Text = "Relâcher"
					UI.setButtonColor(release, COLORS.Gray)
				end
			end)
		end)
	end
end

local function refresh()
	local data = State.Data
	local frame = InventoryMenu.Frame
	if not data or not frame then
		return
	end

	nestLabel.Text = `🏠 Nid : {#data.Dragons} / {data.Capacity} places`
	if data.NestUpgradePrice then
		upgradeButton.Text = `Agrandir ({Format.Short(data.NestUpgradePrice)} 🪙)`
	elseif not State.HasPass("BigNest") or not State.HasPass("GiantNest") then
		upgradeButton.Text = "Plus de places (R$)"
	else
		upgradeButton.Text = "Nid au maximum"
	end

	local groups = InventoryMenu.Groups(data.Dragons)
	local fusable = 0
	for _, group in groups do
		if InventoryMenu.CanFuse(group) then
			fusable += 1
		end
	end
	fuseAllButton.Visible = fusable > 0

	if not frame.Visible then
		return -- on ne reconstruit les cartes 3D que si la fenêtre est ouverte
	end
	UI.clear(grid)
	if #groups == 0 then
		label({
			Size = UDim2.new(1, 0, 0, 30),
			Text = "Ton nid est vide : va ouvrir un œuf ! 🥚",
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = grid,
		})
	end
	for order, group in groups do
		card(order, group)
	end
end

function InventoryMenu.Build(gui: ScreenGui)
	local frame, list = UI.panel(gui, "🐉 Mes dragons", COLORS.Purple)
	InventoryMenu.Frame = frame

	local header = make("Frame", {
		Size = UDim2.new(1, -8, 0, 40),
		BackgroundTransparency = 1,
		LayoutOrder = 0,
		Parent = list,
	})
	nestLabel = label({ Size = UDim2.new(0.42, 0, 1, 0), Text = "", Parent = header })
	upgradeButton = button({
		Position = UDim2.fromScale(0.43, 0),
		Size = UDim2.new(0.3, -6, 1, 0),
		Text = "Agrandir",
		Parent = header,
	}, COLORS.Blue)
	upgradeButton.Activated:Connect(function()
		local data = State.Data
		if data and data.NestUpgradePrice then
			Remotes.UpgradeNest:FireServer()
		elseif not State.HasPass("BigNest") then
			Purchase.Prompt("Pass", "BigNest")
		elseif not State.HasPass("GiantNest") then
			Purchase.Prompt("Pass", "GiantNest")
		end
	end)
	fuseAllButton = button({
		Position = UDim2.fromScale(0.73, 0),
		Size = UDim2.new(0.27, 0, 1, 0),
		Text = "🔁 Tout fusionner",
		Visible = false,
		Parent = header,
	}, COLORS.Green)
	fuseAllButton.Activated:Connect(function()
		Remotes.Fuse:FireServer("All")
	end)

	grid = make("Frame", {
		Size = UDim2.new(1, -8, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 1,
		Parent = list,
	}, { make("UIGridLayout", {
		CellSize = UDim2.fromOffset(132, 182),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) })

	State.DataChanged:Connect(refresh)
	UI.PanelOpened:Connect(function(opened)
		if opened == frame then
			refresh()
		end
	end)
	refresh()
end

return InventoryMenu
