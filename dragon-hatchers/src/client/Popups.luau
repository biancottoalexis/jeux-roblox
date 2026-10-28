-- Fenêtres qui s'ouvrent toutes seules : propositions d'achat au bon moment,
-- gains hors ligne au retour du joueur, et messages de fusion.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Dragons = require(Shared.Dragons)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)

local UI = require(script.Parent.UI)
local Purchase = require(script.Parent.Purchase)
local Toast = require(script.Parent.Toast)

local Popups = {}

local COLORS = UI.COLORS
local label, button = UI.label, UI.button

local gui: ScreenGui

-- Petite fenêtre au centre avec un titre, un texte et des boutons
local function modal(title: string, accent: Color3, lines: { string }, actions: { { Text: string, Color: Color3, OnClick: (() -> ())? } })
	UI.clear(gui)
	local frame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(380, 150 + #lines * 30),
		BackgroundColor3 = COLORS.Panel,
		Parent = gui,
	}, { UI.corner(18), UI.stroke(accent, 4) })

	local header = UI.make("Frame", {
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = frame,
	}, { UI.corner(18), UI.gradient(accent) })
	label({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 32), Text = title, TextXAlignment = Enum.TextXAlignment.Center, Parent = header })

	for i, line in lines do
		label({
			Position = UDim2.fromOffset(16, 56 + (i - 1) * 30),
			Size = UDim2.new(1, -32, 0, 26),
			Text = line,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = if i == 1 then COLORS.Text else COLORS.Muted,
			Parent = frame,
		})
	end

	local width = 1 / #actions
	for i, action in actions do
		local b = button({
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(width * (i - 1), if i == 1 then 14 else 6, 1, -14),
			Size = UDim2.new(width, -20, 0, 48),
			Text = action.Text,
			Parent = frame,
		}, action.Color)
		b.Activated:Connect(function()
			frame:Destroy()
			if action.OnClick then
				action.OnClick()
			end
		end)
	end
	UI.bounce(frame)
	return frame
end

local function showOffer(kind: string, key: string, message: string)
	local item = Purchase.Item(kind, key)
	if not item then
		return
	end
	modal("💎 Offre spéciale", COLORS.Pink, { message, `{item.Name} : {item.Description}` }, {
		{ Text = "Non merci", Color = COLORS.Gray },
		{
			Text = `Acheter {Purchase.PriceText(kind, key)}`,
			Color = COLORS.Green,
			OnClick = function()
				Purchase.Prompt(kind, key)
			end,
		},
	})
end

local function showOfflineEarnings(amount: number, seconds: number, hasPass: boolean)
	local lines = {
		`Pendant ton absence ({Format.Duration(seconds)}), tes dragons ont gagné :`,
		`🪙 {Format.Short(amount)} or !`,
	}
	local actions = { { Text = "Super !", Color = COLORS.Green } }
	if not hasPass then
		table.insert(lines, "Avec « Gains hors ligne + » : 24 h à 100 % !")
		table.insert(actions, {
			Text = `Doubler ({Purchase.PriceText("Pass", "OfflinePlus")})`,
			Color = COLORS.Pink,
			OnClick = function()
				Purchase.Prompt("Pass", "OfflinePlus")
			end,
		})
	end
	modal("🌙 Bon retour !", COLORS.Purple, lines, actions)
end

local function onFused(results: { any }, automatic: boolean, upgraded: number)
	local best = results[#results]
	local text = if #results == 1 then `🔁 Fusion : {Dragons.FullName(best)} !` else `🔁 {#results} fusions ! Meilleur : {Dragons.FullName(best)}`
	Toast.Show(if automatic then `⚙ {text}` else text, COLORS.Green)
	if upgraded > 0 and not automatic then
		Toast.Show("✨ Une mutation est apparue pendant la fusion !", COLORS.Pink)
	end
end

function Popups.Start()
	gui = UI.make("ScreenGui", {
		Name = "Popups",
		ResetOnSpawn = false,
		DisplayOrder = 12,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	Remotes.Offer.OnClientEvent:Connect(showOffer)
	Remotes.OfflineEarnings.OnClientEvent:Connect(showOfflineEarnings)
	Remotes.Fused.OnClientEvent:Connect(onFused)
	Remotes.Notify.OnClientEvent:Connect(function(message: string)
		Toast.Show(message)
	end)
end

return Popups
