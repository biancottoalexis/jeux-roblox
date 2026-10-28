-- La carte et les personnages.
--
-- Si workspace ne contient pas de dossier "Map", une carte complète est
-- générée en code (îles, ponts, barrières, œufs, décor) pour que le jeu soit
-- jouable tout de suite. Pour utiliser ta propre carte faite dans Studio,
-- crée un dossier workspace.Map avec :
--   Map.Eggs.<Id de zone>   : une Part (l'œuf) par zone, ex. Map.Eggs.Prairie
--   Map.Gates.<Id de zone>  : une Part (la barrière) par zone à débloquer
--   Map.Spawns.<Id de zone> : une Part où arrive le joueur qui se téléporte
-- (les Id de zone sont dans Zones.luau : Prairie, Volcan, Ocean, Ciel, Neant)
--
-- Gère aussi les effets des Game Passes sur le personnage : vitesse, titre
-- VIP, aura, et la téléportation.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Dragons = require(Shared.Dragons)
local Format = require(Shared.Format)
local Remotes = require(Shared.Remotes)
local Zones = require(Shared.Zones)

local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local EconomyService = require(script.Parent.EconomyService)
local DragonService = require(script.Parent.DragonService)

local WorldService = {}

local spawnPositions: { [number]: Vector3 } = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		if key ~= "Parent" then
			(p :: any)[key] = value
		end
	end
	p.Parent = props.Parent
	return p
end

local function billboard(adornee: BasePart, offset: Vector3, size: UDim2, lines: { { Text: string, Color: Color3?, Scale: number? } })
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = 120
	gui.LightInfluence = 0
	gui.Adornee = adornee

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = gui

	local total = 0
	for _, line in lines do
		total += line.Scale or 1
	end
	for index, line in lines do
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, (line.Scale or 1) / total)
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.Text = line.Text
		label.TextColor3 = line.Color or Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.2
		label.LayoutOrder = index
		label.Parent = gui
	end
	gui.Parent = adornee
	return gui
end

---------------------------------------------------------------------------
-- Œufs et barrières (pour la carte générée ou la tienne)
---------------------------------------------------------------------------

local function setupEgg(egg: BasePart, zoneIndex: number)
	local zone = Zones.Get(zoneIndex)
	DragonService.SetEggPosition(zoneIndex, egg.Position)

	local lines = {
		{ Text = zone.EggName, Color = zone.EggColor, Scale = 1.4 },
		{ Text = `{Format.Short(zone.EggPrice)} 🪙`, Color = Color3.fromRGB(255, 220, 80), Scale = 1.2 },
	}
	-- Les chances sont affichées sur l'œuf (obligatoire pour les tirages sur Roblox)
	local chances = Dragons.RarityChances()
	for _, rarity in Dragons.RarityOrder do
		local species = Dragons.Species[Dragons.SpeciesByZone[zoneIndex][rarity]]
		table.insert(lines, {
			Text = `{species.DisplayName} : {string.format("%g", chances[rarity])} %`,
			Color = Dragons.Rarities[rarity].Color,
		})
	end
	billboard(egg, Vector3.new(0, egg.Size.Y / 2 + 6, 0), UDim2.fromOffset(260, 170), lines)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Ouvrir"
	prompt.ObjectText = `{zone.EggName} ({Format.Short(zone.EggPrice)} 🪙)`
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Config.Hatch.PromptDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = egg
	prompt.Triggered:Connect(function(player)
		DragonService.Hatch(player, zoneIndex)
	end)
end

local function setupGate(gate: BasePart, zoneIndex: number)
	local zone = Zones.Get(zoneIndex)
	gate:SetAttribute("ZoneId", zone.Id) -- le client la rend traversable une fois débloquée
	billboard(gate, Vector3.new(0, gate.Size.Y / 2 + 3, 0), UDim2.fromOffset(240, 70), {
		{ Text = `🔒 {zone.DisplayName}`, Color = zone.EggColor, Scale = 1.2 },
		{ Text = `{Format.Short(zone.UnlockPrice)} 🪙`, Color = Color3.fromRGB(255, 220, 80) },
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Débloquer"
	prompt.ObjectText = `{zone.DisplayName} ({Format.Short(zone.UnlockPrice)} 🪙)`
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = gate
	prompt.Triggered:Connect(function(player)
		EconomyService.UnlockZone(player, zoneIndex)
	end)
end

---------------------------------------------------------------------------
-- Carte générée en code
---------------------------------------------------------------------------

local function decorate(folder: Folder, zoneIndex: number, center: Vector3)
	local rng = Random.new(zoneIndex * 1000) -- même décor à chaque partie
	local zone = Zones.Get(zoneIndex)
	local half = Zones.IslandSize / 2 - 10

	local function randomSpot(): Vector3?
		for _ = 1, 10 do
			local x, z = rng:NextNumber(-half, half), rng:NextNumber(-half, half)
			-- on laisse libres le centre (œuf, arrivée) et le chemin vers les ponts
			if math.abs(z) > 14 and (x * x + z * z) > 45 * 45 then
				return center + Vector3.new(x, 0, z)
			end
		end
		return nil
	end

	for _ = 1, 16 do
		local spot = randomSpot()
		if not spot then
			continue
		end
		if zone.Id == "Prairie" then
			local height = rng:NextNumber(8, 14)
			part({ Size = Vector3.new(2, height, 2), Position = spot + Vector3.new(0, height / 2, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, Parent = folder })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(8, 12), Position = spot + Vector3.new(0, height, 0), Color = Color3.fromRGB(60, 150, 60), Material = Enum.Material.Grass, Parent = folder })
		elseif zone.Id == "Volcan" then
			local size = rng:NextNumber(4, 9)
			part({ Size = Vector3.new(size, size * 0.8, size), Position = spot + Vector3.new(0, size * 0.3, 0), Orientation = Vector3.new(rng:NextNumber(0, 30), rng:NextNumber(0, 360), 0), Color = Color3.fromRGB(45, 35, 35), Material = Enum.Material.Basalt, Parent = folder })
			part({ Size = Vector3.new(size * 1.4, 0.2, size * 1.4), Position = spot + Vector3.new(size * 1.2, 0.1, 0), Color = Color3.fromRGB(255, 90, 20), Material = Enum.Material.Neon, Parent = folder })
		elseif zone.Id == "Ocean" then
			local height = rng:NextNumber(6, 16)
			local spike = Instance.new("WedgePart")
			spike.Anchored = true
			spike.Size = Vector3.new(3, height, 4)
			spike.Position = spot + Vector3.new(0, height / 2, 0)
			spike.Orientation = Vector3.new(0, rng:NextNumber(0, 360), 0)
			spike.Color = Color3.fromRGB(170, 220, 255)
			spike.Material = Enum.Material.Ice
			spike.Transparency = 0.2
			spike.Parent = folder
		elseif zone.Id == "Ciel" then
			for i = 1, 3 do
				part({ Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(5, 9), Position = spot + Vector3.new(i * 3, rng:NextNumber(2, 4), rng:NextNumber(-2, 2)), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = folder })
			end
		else
			local size = rng:NextNumber(2, 4)
			part({ Size = Vector3.new(size, size * 3, size), Position = spot + Vector3.new(0, rng:NextNumber(4, 10), 0), Orientation = Vector3.new(rng:NextNumber(0, 45), rng:NextNumber(0, 360), rng:NextNumber(0, 45)), Color = Color3.fromRGB(170, 90, 255), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
		end
	end
end

local function buildIsland(map: Folder, zoneIndex: number)
	local zone = Zones.Get(zoneIndex)
	local center = Zones.Center(zoneIndex)
	local folder = Instance.new("Folder")
	folder.Name = zone.Id
	folder.Parent = map

	local size = Zones.IslandSize
	part({ Name = "Sol", Size = Vector3.new(size, 6, size), Position = center - Vector3.new(0, 3, 0), Color = zone.Ground, Material = zone.Material, Parent = folder })
	-- Dessous de l'île, pour l'effet « île flottante »
	part({ Size = Vector3.new(size - 16, 24, size - 16), Position = center - Vector3.new(0, 18, 0), Color = Color3.fromRGB(90, 70, 55), Material = Enum.Material.Rock, Parent = folder })
	part({ Size = Vector3.new(size - 50, 20, size - 50), Position = center - Vector3.new(0, 38, 0), Color = Color3.fromRGB(80, 60, 50), Material = Enum.Material.Rock, Parent = folder })

	-- Pancarte de la zone
	local sign = part({ Size = Vector3.new(1, 1, 1), Position = center + Vector3.new(0, 1, 30), Transparency = 1, CanCollide = false, Parent = folder })
	billboard(sign, Vector3.new(0, 10, 0), UDim2.fromOffset(300, 60), { { Text = zone.DisplayName, Color = zone.EggColor } })

	-- Socle et œuf
	local pedestal = part({ Name = "Socle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 12, 12), CFrame = CFrame.new(center + Vector3.new(0, 1, -35)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(230, 230, 240), Material = Enum.Material.Marble, Parent = folder })
	local egg = part({ Name = "Egg", Size = Vector3.new(5, 7, 5), Position = pedestal.Position + Vector3.new(0, 4.5, 0), Color = zone.EggColor, Material = Enum.Material.SmoothPlastic, Parent = folder })
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = egg
	local light = Instance.new("PointLight")
	light.Color = zone.EggColor
	light.Range = 14
	light.Parent = egg
	setupEgg(egg, zoneIndex)

	spawnPositions[zoneIndex] = center + Vector3.new(0, 4, 8)
	decorate(folder, zoneIndex, center)

	-- Pont et barrière vers la zone précédente
	if zoneIndex > 1 then
		local x = center.X - Zones.Spacing / 2
		local gap = Zones.Spacing - size
		part({ Name = "Pont", Size = Vector3.new(gap + 4, 2, 20), Position = Vector3.new(x, -1, 0), Color = Color3.fromRGB(140, 100, 60), Material = Enum.Material.WoodPlanks, Parent = folder })
		local gate = part({
			Name = "Gate",
			Size = Vector3.new(2, 18, 20),
			Position = Vector3.new(x, 9, 0),
			Color = zone.EggColor,
			Material = Enum.Material.ForceField,
			Transparency = 0.2,
			Parent = folder,
		})
		setupGate(gate, zoneIndex)
	end
end

local function buildMap()
	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end

	local map = Instance.new("Folder")
	map.Name = "GeneratedMap"
	map.Parent = workspace
	for index in Zones.List do
		buildIsland(map, index)
	end

	-- La mer tout en bas : si on tombe, on revient sur la dernière île visitée
	local sea = part({
		Name = "Mer",
		Size = Vector3.new(2048, 4, 2048),
		Position = Vector3.new(Zones.Spacing * 2, -70, 0),
		Color = Color3.fromRGB(40, 120, 210),
		Material = Enum.Material.Glass,
		Transparency = 0.15,
		Parent = map,
	})
	sea.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not player or not root then
			return
		end
		-- Île la plus proche parmi celles que le joueur a débloquées
		local data = DataService.Get(player)
		local best, bestDistance = spawnPositions[1], math.huge
		for index, position in spawnPositions do
			local zone = Zones.Get(index)
			local distance = math.abs(position.X - root.Position.X)
			if data and data.Zones[zone.Id] and distance < bestDistance then
				best, bestDistance = position, distance
			end
		end
		(character :: Model):PivotTo(CFrame.new(best))
	end)

	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Anchored = true
		spawn.Size = Vector3.new(8, 1, 8)
		spawn.Parent = workspace
	end
	local spawnLocation = spawn :: SpawnLocation
	spawnLocation.Position = Zones.Center(1) + Vector3.new(0, 0.5, 8)
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Duration = 0 -- pas de bulle de protection
end

-- Utilise la carte faite dans Studio (dossier workspace.Map)
local function useCustomMap(map: Instance)
	local eggs = map:FindFirstChild("Eggs")
	local gates = map:FindFirstChild("Gates")
	local spawns = map:FindFirstChild("Spawns")
	for index, zone in Zones.List do
		local egg = eggs and eggs:FindFirstChild(zone.Id)
		if egg and egg:IsA("BasePart") then
			setupEgg(egg, index)
		else
			warn(`[WorldService] Œuf manquant : workspace.Map.Eggs.{zone.Id}`)
		end
		local gate = gates and gates:FindFirstChild(zone.Id)
		if gate and gate:IsA("BasePart") then
			setupGate(gate, index)
		end
		local spawnPart = spawns and spawns:FindFirstChild(zone.Id)
		if spawnPart and spawnPart:IsA("BasePart") then
			spawnPositions[index] = spawnPart.Position + Vector3.new(0, 4, 0)
		elseif egg and egg:IsA("BasePart") then
			spawnPositions[index] = egg.Position + Vector3.new(0, 2, 12)
		end
	end
end

local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.3
		atmosphere.Color = Color3.fromRGB(200, 220, 255)
		atmosphere.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.6
		bloom.Threshold = 1.6
		bloom.Parent = Lighting
	end
end

---------------------------------------------------------------------------
-- Personnages : effets des Game Passes
---------------------------------------------------------------------------

local function applyCharacterPerks(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	if not humanoid or not root or not head then
		return
	end

	humanoid.WalkSpeed = if MonetizationService.HasPass(player, "Speed") then Config.Movement.FastWalkSpeed else Config.Movement.WalkSpeed

	local isVip = MonetizationService.HasPass(player, "VIP")
	player:SetAttribute("VIP", isVip)
	if isVip and not head:FindFirstChild("VipTag") then
		local tag = billboard(head :: BasePart, Vector3.new(0, 2.4, 0), UDim2.fromOffset(120, 26), {
			{ Text = "👑 VIP", Color = Color3.fromRGB(255, 205, 60) },
		})
		tag.Name = "VipTag"
		tag.MaxDistance = 60
	end

	if MonetizationService.HasPass(player, "Aura") and not root:FindFirstChild("Aura") then
		local attachment = Instance.new("Attachment")
		attachment.Name = "Aura"
		attachment.Parent = root
		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 150, 40), Color3.fromRGB(255, 40, 120))
		particles.LightEmission = 1
		particles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		particles.Transparency = NumberSequence.new(0.2, 1)
		particles.Lifetime = NumberRange.new(0.8, 1.2)
		particles.Rate = 30
		particles.Speed = NumberRange.new(1, 3)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Parent = attachment
	end
end

local function teleport(player: Player, zoneIndex: unknown)
	if typeof(zoneIndex) ~= "number" or not MonetizationService.HasPass(player, "Teleport") then
		return
	end
	local zone = Zones.Get(zoneIndex)
	local data = DataService.Get(player)
	local character = player.Character
	local target = spawnPositions[zoneIndex]
	if zone and data and data.Zones[zone.Id] and character and target then
		character:PivotTo(CFrame.new(target))
	end
end

function WorldService.Init()
	setupLighting()
	local map = workspace:FindFirstChild("Map")
	if map then
		useCustomMap(map)
	else
		buildMap()
	end
end

function WorldService.Start()
	Remotes.Teleport.OnServerEvent:Connect(teleport)

	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("HumanoidRootPart", 5)
			character:WaitForChild("Head", 5)
			applyCharacterPerks(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	DataService.PlayerLoaded:Connect(applyCharacterPerks)
	MonetizationService.PassAdded:Connect(applyCharacterPerks)
end

return WorldService
