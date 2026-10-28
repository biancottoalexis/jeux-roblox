-- Notifications qui apparaissent en haut de l'écran et s'empilent.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = require(script.Parent.UI)

local Toast = {}

local MAX_VISIBLE = 4
local holder: Frame? = nil
local order = 0

local function getHolder(): Frame
	if holder then
		return holder
	end
	local gui = UI.make("ScreenGui", {
		Name = "Toasts",
		ResetOnSpawn = false,
		DisplayOrder = 20,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	local frame = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.new(0.6, 0, 0, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		UI.make("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UI.make("UISizeConstraint", { MaxSize = Vector2.new(520, 200) }),
	})
	holder = frame
	return frame
end

function Toast.Show(text: string, color: Color3?)
	local parent = getHolder()
	local visible = {}
	for _, child in parent:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(visible, child)
		end
	end
	if #visible >= MAX_VISIBLE then
		table.sort(visible, function(a, b)
			return a.LayoutOrder < b.LayoutOrder
		end)
		visible[1]:Destroy()
	end

	order += 1
	local label = UI.label({
		Size = UDim2.new(1, 0, 0, 30),
		Text = text,
		TextColor3 = color or UI.COLORS.Gold,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = order,
		Parent = parent,
	})
	UI.bounce(label)
	task.delay(3.5, function()
		if not label.Parent then
			return
		end
		local strokeFade = label:FindFirstChildOfClass("UIStroke")
		if strokeFade then
			TweenService:Create(strokeFade, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		end
		TweenService:Create(label, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
		task.wait(0.5)
		label:Destroy()
	end)
end

return Toast
