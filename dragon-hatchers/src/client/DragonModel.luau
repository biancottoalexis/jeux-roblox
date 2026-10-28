-- Fabrique le modèle 3D d'un dragon (pour ceux qui suivent le joueur, les
-- icônes de l'inventaire et l'animation d'éclosion).
--
-- Par défaut, le dragon est construit avec des pièces simples, aux couleurs
-- de son espèce. Pour utiliser tes propres modèles (Toolbox ou Blender),
-- mets-les dans ReplicatedStorage.DragonModels avec le nom de l'espèce
-- (ex. "PrairieCommun", voir Dragons.luau).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dragons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Dragons"))

local DragonModel = {}

export type Rig = {
	Model: Model,
	-- Ailes : pièce et position par rapport au centre du dragon (pour les faire battre)
	Wings: { { Part: BasePart, Offset: CFrame, Side: number } },
	-- Pièces à recolorer en boucle pour la mutation Arc-en-ciel
	RainbowParts: { BasePart },
}

local GOLD = Color3.fromRGB(255, 200, 40)
local COSMIC_BODY = Color3.fromRGB(30, 18, 70)
local COSMIC_GLOW = Color3.fromRGB(190, 110, 255)

local function sparkles(parent: BasePart, color: Color3, rate: number)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	emitter.Lifetime = NumberRange.new(0.6, 1.2)
	emitter.Rate = rate
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = attachment
end

-- Modèle fourni par le créateur dans ReplicatedStorage.DragonModels
local function customModel(species: string, scale: number): Model?
	local folder = ReplicatedStorage:FindFirstChild("DragonModels")
	local template = folder and folder:FindFirstChild(species)
	if not template or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	pcall(function()
		model:ScaleTo(model:GetScale() * scale)
	end)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
		end
	end
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
	end
	return model
end

-- Construit un dragon. scale = taille (1 = environ la taille d'un joueur).
function DragonModel.Build(dragon: { S: string, L: number, M: string }, scale: number): Rig
	local def = Dragons.Species[dragon.S]
	local size = scale * (1 + (dragon.L - 1) * 0.18) -- un peu plus grand à chaque niveau
	local rig: Rig = { Model = nil :: any, Wings = {}, RainbowParts = {} }

	local main = def and def.Color or Color3.new(1, 1, 1)
	local accent = def and def.Accent or Color3.new(1, 1, 1)
	local material = Enum.Material.SmoothPlastic
	local accentMaterial = Enum.Material.SmoothPlastic
	local reflectance = 0
	if dragon.M == "Dore" then
		main, reflectance = GOLD, 0.25
	elseif dragon.M == "Cosmique" then
		main, accent, accentMaterial = COSMIC_BODY, COSMIC_GLOW, Enum.Material.Neon
	end

	local custom = customModel(dragon.S, size)
	if custom then
		rig.Model = custom
	else
		local model = Instance.new("Model")
		model.Name = "Dragon"
		rig.Model = model

		local function piece(name: string, shape: string, partSize: Vector3, offset: CFrame, color: Color3, isAccent: boolean?): BasePart
			local p: BasePart = if shape == "Wedge" then Instance.new("WedgePart") else Instance.new("Part")
			p.Name = name
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
			p.Size = partSize * size
			p.CFrame = CFrame.new(offset.Position * size) * offset.Rotation
			p.Color = color
			p.Material = if isAccent then accentMaterial else material
			p.Reflectance = if isAccent then 0 else reflectance
			p.TopSurface = Enum.SurfaceType.Smooth
			p.BottomSurface = Enum.SurfaceType.Smooth
			if shape == "Ellipse" then
				local mesh = Instance.new("SpecialMesh")
				mesh.MeshType = Enum.MeshType.Sphere
				mesh.Parent = p
			elseif shape == "Ball" and p:IsA("Part") then
				p.Shape = Enum.PartType.Ball
			end
			p.Parent = model
			if dragon.M == "ArcEnCiel" and color ~= Color3.new(0, 0, 0) and color ~= Color3.new(1, 1, 1) then
				table.insert(rig.RainbowParts, p)
			end
			return p
		end

		local body = piece("Body", "Ellipse", Vector3.new(3, 2.6, 4.2), CFrame.new(), main)
		model.PrimaryPart = body
		piece("Belly", "Ellipse", Vector3.new(2.2, 1.8, 3.2), CFrame.new(0, -0.5, -0.3), accent, true)
		piece("Head", "Ellipse", Vector3.new(2.3, 2.1, 2.4), CFrame.new(0, 1.5, -2.3), main)
		piece("Snout", "Ellipse", Vector3.new(1.5, 1.05, 1.5), CFrame.new(0, 1.15, -3.4), main)
		for _, side in { -1, 1 } do
			piece("Eye", "Ball", Vector3.one * 0.55, CFrame.new(side * 0.62, 1.85, -3.2), Color3.new(0, 0, 0))
			piece("Shine", "Ball", Vector3.one * 0.2, CFrame.new(side * 0.55, 1.98, -3.45), Color3.new(1, 1, 1))
			piece("Horn", "Wedge", Vector3.new(0.3, 1.1, 0.7), CFrame.new(side * 0.55, 2.75, -1.9) * CFrame.Angles(math.rad(-25), 0, 0), accent, true)
			piece("Leg", "Ball", Vector3.one * 0.95, CFrame.new(side * 0.95, -1.2, -1.1), main)
			piece("Leg", "Ball", Vector3.one * 0.95, CFrame.new(side * 0.95, -1.2, 1.1), main)

			local offset = CFrame.new(side * 2, 1.4, 0.3) * CFrame.Angles(0, 0, math.rad(side * -30))
			local wing = piece(if side < 0 then "WingL" else "WingR", "Wedge", Vector3.new(0.2, 2.4, 3.4), offset, accent, true)
			table.insert(rig.Wings, { Part = wing, Offset = CFrame.new(offset.Position * size) * offset.Rotation, Side = side })
		end
		piece("Tail", "Ellipse", Vector3.new(1.3, 1.2, 2.6), CFrame.new(0, 0.1, 2.6), main)
		piece("Tail", "Ellipse", Vector3.new(0.8, 0.8, 2), CFrame.new(0, 0.45, 4), main)
		piece("TailTip", "Wedge", Vector3.new(0.3, 0.9, 1), CFrame.new(0, 0.7, 5) * CFrame.Angles(0, math.rad(180), 0), accent, true)
	end

	local primary = rig.Model.PrimaryPart
	if primary then
		if dragon.M == "Dore" then
			sparkles(primary, GOLD, 6)
		elseif dragon.M == "ArcEnCiel" then
			sparkles(primary, Color3.fromRGB(255, 150, 230), 10)
		elseif dragon.M == "Cosmique" then
			sparkles(primary, Color3.new(1, 1, 1), 20)
			local light = Instance.new("PointLight")
			light.Color = COSMIC_GLOW
			light.Range = 10 * size
			light.Parent = primary
		end
	end
	return rig
end

-- Place le dragon et fait battre ses ailes. t = temps (os.clock()).
function DragonModel.Pose(rig: Rig, cframe: CFrame, t: number)
	rig.Model:PivotTo(cframe)
	local flap = math.sin(t * 9) * math.rad(28)
	for _, wing in rig.Wings do
		wing.Part.CFrame = cframe * wing.Offset * CFrame.Angles(0, 0, wing.Side * flap)
	end
	for index, part in rig.RainbowParts do
		part.Color = Color3.fromHSV((t * 0.4 + index * 0.08) % 1, 0.75, 1)
	end
end

return DragonModel
