-- Ce que le client sait du joueur : ses données (dragons, zones, passes...).
-- L'or est lu directement sur l'attribut "Gold" du joueur.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local State = {}

State.Data = nil :: any

local dataChanged = Instance.new("BindableEvent")

-- () : les données ont changé
State.DataChanged = dataChanged.Event

function State.HasPass(key: string): boolean
	return State.Data ~= nil and table.find(State.Data.Passes or {}, key) ~= nil
end

function State.Gold(): number
	return game:GetService("Players").LocalPlayer:GetAttribute("Gold") or 0
end

Remotes.Data.OnClientEvent:Connect(function(data)
	State.Data = data
	dataChanged:Fire()
end)

Remotes.Data:FireServer()

return State
