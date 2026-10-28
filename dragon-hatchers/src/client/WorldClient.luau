-- Ce que chaque joueur voit différemment dans le monde :
--   - les barrières des zones qu'il a débloquées disparaissent (pour lui seul)
--   - le titre [VIP] dans le chat pour les joueurs VIP

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

local State = require(script.Parent.State)

local WorldClient = {}

local function refreshGates()
	local data = State.Data
	if not data then
		return
	end
	for _, gate in workspace:GetDescendants() do
		if gate:IsA("BasePart") and gate:GetAttribute("ZoneId") then
			local open = data.Zones[gate:GetAttribute("ZoneId")] == true
			gate.CanCollide = not open
			gate.Transparency = if open then 1 else 0.2
			for _, child in gate:GetChildren() do
				if child:IsA("BillboardGui") then
					child.Enabled = not open
				elseif child:IsA("ProximityPrompt") then
					child.Enabled = not open
				end
			end
		end
	end
end

function WorldClient.Start()
	State.DataChanged:Connect(refreshGates)
	refreshGates()

	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("VIP") then
			properties.PrefixText = `<font color="#FFCD3C">[👑 VIP]</font> {message.PrefixText}`
		end
		return properties
	end
end

return WorldClient
