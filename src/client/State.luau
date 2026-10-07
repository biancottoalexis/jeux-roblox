-- Ce que le client sait : données du joueur et temps de recharge en cours.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local State = {}

State.Data = nil :: any
State.Cooldowns = {} :: { [string]: { Ends: number, Duration: number } }

local dataChanged = Instance.new("BindableEvent")
local cooldownStarted = Instance.new("BindableEvent")

-- () : les données ont changé
State.DataChanged = dataChanged.Event
-- (key, duration, extra) : une action vient d'être utilisée
State.CooldownStarted = cooldownStarted.Event

function State.SetCooldown(key: string, duration: number, extra: any?)
	State.Cooldowns[key] = { Ends = os.clock() + duration, Duration = duration }
	cooldownStarted:Fire(key, duration, extra)
end

function State.IsOnCooldown(key: string): boolean
	local cooldown = State.Cooldowns[key]
	return cooldown ~= nil and cooldown.Ends > os.clock()
end

Remotes.Data.OnClientEvent:Connect(function(data)
	State.Data = data
	dataChanged:Fire()
end)

Remotes.Cooldown.OnClientEvent:Connect(function(key, duration, extra)
	State.SetCooldown(key, duration, extra)
end)

Remotes.Data:FireServer()

return State
