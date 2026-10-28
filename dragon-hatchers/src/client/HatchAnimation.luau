-- Animation d'éclosion : l'œuf tremble de plus en plus fort, un flash, puis
-- le dragon apparaît en 3D avec son nom, sa rareté et sa mutation.
-- Les dragons très rares ont droit à un grand « INCROYABLE ! ».

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Dragons = require(Shared.Dragons)
local Remotes = require(Shared.Remotes)
local Zones = require(Shared.Zones)

local UI = require(script.Parent.UI)
local DragonView = require(script.Parent.DragonView)

local HatchAnimation = {}

local COLORS = UI.COLORS

local gui: ScreenGui
local current = 0 -- numéro de l'animation en cours (une nouvelle annule l'ancienne)

local function playSound(id: string)
	if id == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.SoundId = id
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Once(function()
		sound:Destroy()
	end)
end

local function isSpecial(dragon): boolean
	local rarity = Dragons.Rarities[Dragons.Species[dragon.S].Rarity]
	local mutation = Dragons.Mutations[dragon.M]
	return rarity.Order >= 4 or mutation.Order >= 2
end

local function eggViewport(parent: Instance, color: Color3): ViewportFrame
	local viewport = UI.make("ViewportFrame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromScale(0.85, 0.75),
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(180, 180, 200),
		LightDirection = Vector3.new(-1, -1, -0.5),
		Parent = parent,
	})
	local egg = Instance.new("Part")
	egg.Anchored = true
	egg.Size = Vector3.new(4, 5.4, 4)
	egg.Color = color
	egg.Material = Enum.Material.SmoothPlastic
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	egg.Parent = viewport
	-- Taches sur l'œuf
	for i = 1, 5 do
		local spot = Instance.new("Part")
		spot.Anchored = true
		spot.Shape = Enum.PartType.Ball
		spot.Size = Vector3.one * (0.6 + (i % 3) * 0.3)
		spot.Color = Color3.new(1, 1, 1)
		local angle = i * 1.3
		spot.Position = Vector3.new(math.cos(angle) * 1.8, (i - 3) * 0.8, math.sin(angle) * 1.8 - 0.2)
		spot.Parent = viewport
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 1, -10), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end

local function reveal(cell: Frame, dragon)
	local def = Dragons.Species[dragon.S]
	local rarity = Dragons.Rarities[def.Rarity]
	local mutation = Dragons.Mutations[dragon.M]

	-- Rayons de lumière derrière le dragon
	local glow = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(0.9, 0.7),
		BackgroundColor3 = mutation.Color or rarity.Color,
		BackgroundTransparency = 0.55,
		Parent = cell,
	}, { UI.make("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		BackgroundTransparency = 0.8,
	}):Play()

	local view = DragonView.Create(dragon, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromScale(1, 0.75),
		Parent = cell,
	}, true)
	UI.bounce(view)

	UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -38),
		Size = UDim2.new(1, -8, 0.11, 0),
		Text = def.DisplayName,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = cell,
	})
	UI.label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -8, 0.1, 0),
		Text = if mutation.DisplayName ~= "" then `✨ {mutation.DisplayName} • {rarity.DisplayName}` else rarity.DisplayName,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = mutation.Color or rarity.Color,
		Parent = cell,
	})
end

local function play(hatched: { any }, zoneIndex: number, fast: boolean)
	current += 1
	local id = current
	UI.clear(gui)

	local zone = Zones.Get(zoneIndex)
	local count = #hatched
	local cellSize = if count == 1 then Vector2.new(280, 320) elseif count <= 3 then Vector2.new(210, 250) else Vector2.new(150, 180)

	local background = UI.make("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		Parent = gui,
	})
	local holder = UI.make("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.8),
		BackgroundTransparency = 1,
		Parent = background,
	}, { UI.make("UIGridLayout", {
		CellSize = UDim2.fromOffset(cellSize.X, cellSize.Y),
		CellPadding = UDim2.fromOffset(10, 10),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}) })

	local cells = {}
	local eggs = {}
	for i = 1, count do
		local cell = UI.make("Frame", { BackgroundTransparency = 1, LayoutOrder = i, Parent = holder })
		cells[i] = cell
		eggs[i] = eggViewport(cell, zone and zone.EggColor or COLORS.Gold)
	end

	-- 1. L'œuf tremble de plus en plus fort
	playSound(Config.Sounds.Hatch)
	local shakeTime = if fast then 0.35 else 1.3
	local start = os.clock()
	while os.clock() - start < shakeTime do
		if id ~= current then
			return
		end
		local progress = (os.clock() - start) / shakeTime
		for _, egg in eggs do
			egg.Rotation = math.sin(os.clock() * (20 + progress * 30)) * (5 + progress * 20)
		end
		task.wait()
	end

	-- 2. Flash et apparition des dragons
	local special = false
	for i, cell in cells do
		eggs[i]:Destroy()
		local flash = UI.make("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ZIndex = 5,
			Parent = cell,
		}, { UI.make("UICorner", { CornerRadius = UDim.new(0, 20) }) })
		TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		reveal(cell, hatched[i])
		special = special or isSpecial(hatched[i])
	end
	playSound(if special then Config.Sounds.Rare else Config.Sounds.Reveal)

	if special then
		local banner = UI.label({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0.06, 0),
			Size = UDim2.new(0.7, 0, 0.1, 0),
			Text = "🌟 INCROYABLE ! 🌟",
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = COLORS.Gold,
			Parent = background,
		})
		UI.bounce(banner)
	end

	-- 3. On laisse admirer, puis on referme
	task.wait((if fast then 0.6 else 1.3) + (if special then 1.5 else 0))
	if id ~= current then
		return
	end
	TweenService:Create(background, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.wait(0.25)
	if id == current then
		UI.clear(gui)
	end
end

function HatchAnimation.Start()
	gui = UI.make("ScreenGui", {
		Name = "Hatch",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 15,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	Remotes.Hatched.OnClientEvent:Connect(function(hatched, zoneIndex, fast)
		task.spawn(play, hatched, zoneIndex, fast)
	end)
end

return HatchAnimation
