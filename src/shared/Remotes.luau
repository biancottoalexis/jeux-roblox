-- Canaux de communication entre le client (joueur) et le serveur.
-- Le serveur les crée, le client les attend.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"Combat", -- client -> serveur : "M1", "Block", "Skill"
	"Spin", -- client -> serveur : demande de tirage de grimoire
	"Data", -- serveur -> client : données du joueur (le client peut les redemander)
	"Cooldown", -- serveur -> client : une action vient d'être utilisée
	"Knockback", -- serveur -> client : pousse le personnage du joueur
	"Notify", -- serveur -> client : message à afficher
	"Quest", -- client -> serveur : "Daily" (récompense du jour) ou "Claim", index
	"Order", -- client -> serveur : rejoindre un ordre
	"Leaderboard", -- client -> serveur : demande le classement ; serveur -> client : le classement
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
