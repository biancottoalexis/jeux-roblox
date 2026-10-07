-- Point d'entrée du client : lance l'interface, les animations et les contrôles.

local HUD = require(script:WaitForChild("HUD"))
local Animations = require(script:WaitForChild("Animations"))
local Input = require(script:WaitForChild("Input"))

HUD.Start()
Animations.Start()
Input.Start()
