-- Barre du boss en haut de l'écran : sa vie quand il est là, sinon le temps
-- avant sa prochaine apparition. Lit les attributs posés sur workspace par le
-- BossService.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local UI = require(script.Parent.UI)

local BossBar = {}

local BOSS_COLOR = Color3.fromRGB(200, 20, 40)

function BossBar.Build(gui: ScreenGui)
	local holder = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 8),
		Size = UDim2.new(0.4, 0, 0, 50),
		BackgroundTransparency = 1,
		Parent = gui,
	}, { UI.make("UISizeConstraint", { MinSize = Vector2.new(220, 0), MaxSize = Vector2.new(420, 50) }) })

	local title = UI.label({
		Size = UDim2.new(1, 0, 0, 22),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0.4,
		Parent = holder,
	})
	local fill, text = UI.bar(holder, UDim2.fromOffset(0, 26), UDim2.new(1, 0, 0, 18), BOSS_COLOR)
	local back = fill.Parent :: Frame

	local function update()
		local alive = workspace:GetAttribute("BossAlive")
		back.Visible = alive == true
		if alive then
			local health = workspace:GetAttribute("BossHealth") or 0
			local maxHealth = workspace:GetAttribute("BossMaxHealth") or 1
			title.Text = `👹 {Config.Boss.DisplayName}`
			title.TextColor3 = BOSS_COLOR
			fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
			text.Text = `{UI.formatNumber(health)} / {UI.formatNumber(maxHealth)}`
			return
		end

		local nextSpawn = workspace:GetAttribute("BossNextSpawn")
		if not nextSpawn then
			title.Text = ""
			return
		end
		local remaining = math.max(0, math.floor(nextSpawn - workspace:GetServerTimeNow()))
		title.Text = string.format("👹 Démon dans %d:%02d", remaining // 60, remaining % 60)
		title.TextColor3 = UI.COLORS.Muted
	end

	task.spawn(function()
		while true do
			update()
			task.wait(0.25)
		end
	end)
end

return BossBar
