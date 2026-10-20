-- Effets visuels simples (créés en code, aucune ressource à importer).
-- Tu pourras les remplacer plus tard par des effets faits dans Studio.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Effects = {}

local folder = Instance.new("Folder")
folder.Name = "Effects"
folder.Parent = workspace

local function basePart(color: Color3): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = color
	return part
end

-- Sphère qui grossit puis disparaît
function Effects.Burst(position: Vector3, radius: number, color: Color3, duration: number?)
	local time = duration or 0.4
	local part = basePart(color)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one
	part.Transparency = 0.2
	part.Position = position
	part.Parent = folder

	TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.one * radius * 2,
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, time)
end

-- Rayon rectangulaire qui s'affine puis disparaît
function Effects.Beam(origin: CFrame, length: number, width: number, color: Color3)
	local part = basePart(color)
	part.Size = Vector3.new(width, width, length)
	part.CFrame = origin * CFrame.new(0, 0, -length / 2)
	part.Transparency = 0.1
	part.Parent = folder

	TweenService:Create(part, TweenInfo.new(0.5), {
		Size = Vector3.new(0.2, 0.2, length),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.5)
end

-- Petite "lame" devant le personnage pour les coups de poing
function Effects.Slash(origin: CFrame, color: Color3)
	local part = basePart(color)
	part.Size = Vector3.new(4, 0.2, 2)
	part.CFrame = origin * CFrame.new(0, 0, -3) * CFrame.Angles(0, 0, math.rad(math.random(-40, 40)))
	part.Transparency = 0.3
	part.Parent = folder

	TweenService:Create(part, TweenInfo.new(0.2), {
		Size = Vector3.new(6, 0.05, 3),
		Transparency = 1,
	}):Play()
	Debris:AddItem(part, 0.2)
end

-- Cercle au sol qui annonce une grosse attaque (le boss)
function Effects.Warning(position: Vector3, radius: number, duration: number)
	local part = basePart(Color3.fromRGB(255, 30, 30))
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.3, 2, 2)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	part.Transparency = 0.6
	part.Parent = folder

	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = Vector3.new(0.3, radius * 2, radius * 2),
		Transparency = 0.3,
	}):Play()
	Debris:AddItem(part, duration)
end

-- Projectile visible (déplacé par le CombatService)
function Effects.Orb(position: Vector3, radius: number, color: Color3): Part
	local part = basePart(color)
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * radius
	part.Position = position
	part.Parent = folder

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = radius * 3
	light.Parent = part
	return part
end

-- Chiffre de dégâts qui monte au-dessus de la cible
function Effects.DamageNumber(target: BasePart, amount: number, blocked: boolean)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(100, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-15, 15) / 10, 3, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = target

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = blocked and `🛡 {math.floor(amount)}` or tostring(math.floor(amount))
	label.TextColor3 = blocked and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(255, 80, 80)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	gui.Parent = folder

	TweenService:Create(gui, TweenInfo.new(0.8), { StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(gui, 0.8)
end

return Effects
