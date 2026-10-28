-- Fenêtre « Zones » : liste des zones, et téléportation avec le Game Pass
-- « Téléporteur ».

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Zones = require(Shared.Zones)

local State = require(script.Parent.State)
local UI = require(script.Parent.UI)
local Purchase = require(script.Parent.Purchase)

local ZoneMenu = {}

local COLORS = UI.COLORS
local make, label, button = UI.make, UI.label, UI.button

ZoneMenu.Frame = nil :: Frame?

local list: ScrollingFrame

local function refresh()
	local data = State.Data
	local frame = ZoneMenu.Frame
	if not data or not frame or not frame.Visible then
		return
	end
	UI.clear(list)
	local canTeleport = State.HasPass("Teleport")

	if not canTeleport then
		local banner = make("Frame", {
			Size = UDim2.new(1, -8, 0, 60),
			BackgroundColor3 = Color3.new(1, 1, 1),
			LayoutOrder = 0,
			Parent = list,
		}, { UI.corner(12), UI.stroke(), UI.gradient(COLORS.Blue) })
		label({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -160, 0, 44), Text = "🌀 Va partout en un clic avec le Téléporteur !", TextWrapped = true, Parent = banner })
		local buy = button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(130, 42),
			Text = Purchase.PriceText("Pass", "Teleport"),
			Parent = banner,
		}, COLORS.Green)
		buy.Activated:Connect(function()
			Purchase.Prompt("Pass", "Teleport")
		end)
	end

	for index, zone in Zones.List do
		local unlocked = data.Zones[zone.Id] == true
		local row = make("Frame", {
			Size = UDim2.new(1, -8, 0, 54),
			BackgroundColor3 = COLORS.Card,
			LayoutOrder = index,
			Parent = list,
		}, { UI.corner(12), UI.stroke(zone.EggColor, 3) })
		label({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -160, 0, 24), Text = zone.DisplayName, Parent = row })
		label({
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -160, 0, 18),
			Text = if unlocked then `Œuf : {Format.Short(zone.EggPrice)} 🪙` else `🔒 {Format.Short(zone.UnlockPrice)} 🪙 pour débloquer`,
			TextColor3 = if unlocked then COLORS.Muted else COLORS.Gold,
			Parent = row,
		})
		if unlocked and canTeleport then
			local go = button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -10, 0.5, 0),
				Size = UDim2.fromOffset(120, 40),
				Text = "Y aller",
				Parent = row,
			}, COLORS.Blue)
			go.Activated:Connect(function()
				Remotes.Teleport:FireServer(index)
				UI.closePanels()
			end)
		end
	end
end

function ZoneMenu.Build(gui: ScreenGui)
	local frame
	frame, list = UI.panel(gui, "🗺 Zones", COLORS.Blue)
	ZoneMenu.Frame = frame
	State.DataChanged:Connect(refresh)
	UI.PanelOpened:Connect(function(opened)
		if opened == frame then
			refresh()
		end
	end)
end

return ZoneMenu
