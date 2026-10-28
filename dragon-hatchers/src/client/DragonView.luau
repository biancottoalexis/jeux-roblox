-- Affiche un dragon en 3D dans l'interface (ViewportFrame) : icônes de
-- l'inventaire et animation d'éclosion.

local RunService = game:GetService("RunService")

local DragonModel = require(script.Parent.DragonModel)

local DragonView = {}

-- Crée une vue 3D du dragon. spin = le dragon tourne sur lui-même.
-- Renvoie le ViewportFrame (à détruire quand on n'en a plus besoin).
function DragonView.Create(dragon: { S: string, L: number, M: string }, props: { [string]: any }, spin: boolean?): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Color3.fromRGB(170, 170, 190)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1, -0.5)
	for key, value in props do
		if key ~= "Parent" then
			(viewport :: any)[key] = value
		end
	end

	local rig = DragonModel.Build({ S = dragon.S, L = 1, M = dragon.M }, 1)
	rig.Model.Parent = viewport

	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local center = Vector3.new(0, 0.6, 0.6)
	local function place(angle: number, t: number)
		DragonModel.Pose(rig, CFrame.new() * CFrame.Angles(0, angle, 0), t)
		local direction = Vector3.new(-0.9, 0.45, -1).Unit
		camera.CFrame = CFrame.lookAt(center + direction * 15, center)
	end
	place(0, 0)

	if spin or #rig.RainbowParts > 0 then
		local connection
		connection = RunService.RenderStepped:Connect(function()
			if not viewport.Parent then
				connection:Disconnect()
				return
			end
			local t = os.clock()
			place(if spin then t * 1.5 else 0, t)
		end)
	end
	viewport.Parent = props.Parent
	return viewport
end

return DragonView
