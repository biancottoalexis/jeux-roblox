-- Canaux de communication entre le client (joueur) et le serveur.
-- Le serveur les crée, le client les attend.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Data", -- serveur -> client : données du joueur (le client peut les redemander)
	"Notify", -- serveur -> client : message à afficher
	"Hatched", -- serveur -> client : dragons sortis des œufs (pour l'animation)
	"Fused", -- serveur -> client : résultat d'une fusion
	"Offer", -- serveur -> client : proposition d'achat au bon moment
	"OfflineEarnings", -- serveur -> client : or gagné pendant l'absence
	"Click", -- client -> serveur : clic sur « Récolter »
	"Fuse", -- client -> serveur : fusionner un groupe (clé) ou "All"
	"Release", -- client -> serveur : relâcher un dragon (libère une place)
	"UpgradeNest", -- client -> serveur : agrandir le nid avec de l'or
	"Teleport", -- client -> serveur : aller dans une zone (Game Pass)
	"AutoHatch", -- client -> serveur : activer / couper l'éclosion automatique
}

local Remotes = {}

if RunService:IsServer() then
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		for _, name in NAMES do
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		Remotes[name] = folder[name]
	end
else
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	for _, name in NAMES do
		Remotes[name] = folder:WaitForChild(name)
	end
end

return Remotes
