-- Applique une vitesse temporaire à un personnage (esquive, recul, charge).
-- Utilisé par le client pour son propre personnage et par le serveur pour les PNJ.

local Debris = game:GetService("Debris")

local Movement = {}

function Movement.ApplyVelocity(root: BasePart, velocity: Vector3, duration: number)
	local attachment = Instance.new("Attachment")
	attachment.Name = "MovementAttachment"
	attachment.Parent = root

	local linear = Instance.new("LinearVelocity")
	linear.Attachment0 = attachment
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.MaxForce = math.huge
	linear.VectorVelocity = velocity
	linear.Parent = root

	Debris:AddItem(linear, duration)
	Debris:AddItem(attachment, duration)
end

return Movement
