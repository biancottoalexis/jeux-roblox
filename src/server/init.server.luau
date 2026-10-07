-- Point d'entrée du serveur : démarre tous les services dans l'ordre.

local Services = script:WaitForChild("Services")

local order = {
	"MonetizationService",
	"ProgressionService",
	"CombatService",
	"DummyService",
	-- Le DataService démarre en dernier pour que les autres services soient
	-- déjà prêts quand les données du premier joueur arrivent.
	"DataService",
}

local loaded = {}
for _, name in order do
	loaded[name] = require(Services:WaitForChild(name))
end
for _, name in order do
	loaded[name].Init()
end
for _, name in order do
	loaded[name].Start()
end

print("[Serveur] Jeu prêt !")
