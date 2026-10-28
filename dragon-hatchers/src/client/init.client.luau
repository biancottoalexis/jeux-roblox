-- Point d'entrée du client : lance l'interface, les animations et le monde.

local HUD = require(script:WaitForChild("HUD"))
local HatchAnimation = require(script:WaitForChild("HatchAnimation"))
local Popups = require(script:WaitForChild("Popups"))
local Followers = require(script:WaitForChild("Followers"))
local WorldClient = require(script:WaitForChild("WorldClient"))

HUD.Start()
HatchAnimation.Start()
Popups.Start()
Followers.Start()
WorldClient.Start()
