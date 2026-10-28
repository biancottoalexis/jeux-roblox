# 🐉 Dragon Hatchers (Roblox)

Un simulateur de dragons : fais éclore des œufs, fusionne 3 dragons identiques
pour en obtenir un plus fort, cherche les mutations ultra rares et débloque de
nouvelles îles. Le plan complet du jeu est dans [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).

## Ce qui est déjà fait (version 1)

| Système | Détails |
|---|---|
| **Œufs** | 1 œuf par zone, 4 dragons possibles (Commun 60 %, Rare 30 %, Épique 9 %, Légendaire 1 %). Les chances sont affichées au-dessus de l'œuf |
| **Mutations** | Doré (1/50, x3), Arc-en-ciel (1/500, x10), Cosmique (1/10 000, x50). Les plus rares sont annoncées à tout le serveur |
| **Fusion** | 3 dragons identiques = 1 dragon du niveau suivant (x4 d'or), jusqu'au niveau 5. 2 % de chance d'améliorer la mutation |
| **Or** | Les dragons produisent chaque seconde. Bouton « Récolter » pour en gagner plus vite |
| **Gains hors ligne** | Jusqu'à 8 h à 50 % quand le joueur est absent, avec une fenêtre « Bon retour ! » |
| **Nid** | 12 places au départ, agrandissable avec de l'or (jusqu'à 30) ou en Robux |
| **5 zones** | Prairie, Volcan, Océan glacé, Royaume du Ciel, Néant cosmique, chacune derrière une barrière payante |
| **Carte** | Générée en code (îles flottantes, ponts, décor) pour jouer tout de suite. Remplaçable par ta carte |
| **Dragons 3D** | Construits en code, colorés selon l'espèce et la mutation. Ils volent derrière le joueur |
| **Animation d'éclosion** | L'œuf tremble, flash, puis le dragon apparaît en 3D. « INCROYABLE ! » pour les rares |
| **Boutique** | 23 Game Passes rangés par catégorie et 10 Developer Products, avec le pack du débutant mis en avant |
| **Offres au bon moment** | Nid plein → « Grand nid », beaucoup d'œufs ouverts → « Triple éclosion », etc. |
| **Sauvegarde** | Automatique (DataStore) |

## Structure du projet

```
default.project.json       ← configuration Rojo
src/
  shared/                  → ReplicatedStorage.Shared
    Config.luau            ← ⚙️ équilibrage (or, nid, fusion, offres...)
    Dragons.luau           ← 🐉 espèces, raretés, mutations
    Zones.luau             ← 🗺 zones, prix des œufs et des barrières
    Monetization.luau      ← 💰 tous les Game Passes et produits (IDs à remplir)
    Format.luau, Remotes.luau
  server/                  → ServerScriptService
    Services/
      DataService          ← sauvegarde
      MonetizationService  ← achats Robux
      OfferService         ← propositions d'achat au bon moment
      EconomyService       ← or, production, hors ligne, zones, potions
      DragonService        ← éclosion, fusion, nid, dragons qui suivent
      WorldService         ← carte, œufs, barrières, effets des passes
  client/                  → StarterPlayerScripts
    HUD                    ← écran principal
    InventoryMenu, ShopMenu, ZoneMenu   ← les fenêtres
    HatchAnimation, Popups, Toast       ← animations et messages
    DragonModel, DragonView, Followers  ← dragons en 3D
    UI, State, Purchase, WorldClient
```

Les fichiers que tu modifieras le plus : **Config**, **Dragons**, **Zones** et **Monetization**.

---

## 🚀 Installation

Même méthode que pour ton jeu de grimoires :

1. Installe **Roblox Studio**, **VS Code** et, dans VS Code, les extensions
   **Rojo – Roblox Studio Sync** et **Luau Language Server**.
2. Ouvre ce dossier dans VS Code.
3. Ctrl+Shift+P → **Rojo: Open menu** → **Install Roblox Studio plugin** (une seule fois).
4. Dans Studio, crée un jeu à partir du modèle **Baseplate**.
5. Dans VS Code, **Rojo: Open menu** → **default.project.json** ▶️.
6. Dans Studio : **Plugins** → **Rojo** → **Connect**.
7. Clique sur **▶ Play**.

Tu apparais sur l'île de la Prairie. Va devant l'œuf et appuie sur **E** (ou
touche le bouton sur mobile). Tu as de quoi ouvrir 3 œufs dès le départ.

> Le plateau gris (Baseplate) est supprimé automatiquement : la carte est
> générée en code. Si tu tombes des îles, tu reviens sur la dernière île visitée.

### Tester les Game Passes dans Studio
Les vrais achats ne marchent pas dans Studio. Pour tester l'effet d'un Game
Pass, ajoute sa clé dans `Monetization.StudioTestPasses` (fichier
`src/shared/Monetization.luau`) :

```lua
Monetization.StudioTestPasses = { "GoldX2", "TripleHatch", "AutoHatch" }
```

Ça ne change rien dans le vrai jeu publié.

### Activer la sauvegarde
1. **File → Publish to Roblox**.
2. **Home → Game Settings → Security** → active **Enable Studio Access to API Services**.

---

## 💰 Monétisation

### 1. Créer les Game Passes
Sur https://create.roblox.com/dashboard/creations → ton jeu → **Monetization → Passes** → **Create a Pass**.
Pour chacun : un nom, une image (tu peux faire les images plus tard), puis
**Sale** → mets-le en vente au prix indiqué.

| Clé dans le code | Nom | Prix conseillé | Effet codé |
|---|---|---|---|
| `GoldX2` | Or x2 | 199 R$ | ✅ |
| `SuperGold` | Super Or x2 | 699 R$ | ✅ |
| `OfflinePlus` | Gains hors ligne + | 149 R$ | ✅ |
| `ClickX3` | Récolte x3 | 79 R$ | ✅ |
| `LuckX2` | Chance x2 | 299 R$ | ✅ |
| `SuperLuck` | Super Chance x2 | 899 R$ | ✅ |
| `LegendHunter` | Chasseur de Légendaires | 499 R$ | ✅ |
| `LuckyFusion` | Fusion chanceuse | 349 R$ | ✅ |
| `TripleHatch` | Triple éclosion | 149 R$ | ✅ |
| `OctoHatch` | Octuple éclosion | 599 R$ | ✅ |
| `AutoHatch` | Éclosion automatique | 399 R$ | ✅ |
| `AutoFusion` | Fusion automatique | 249 R$ | ✅ |
| `FastHatch` | Éclosion rapide | 79 R$ | ✅ |
| `Speed` | Vitesse x2 | 99 R$ | ✅ |
| `Teleport` | Téléporteur | 129 R$ | ✅ |
| `BigNest` | Grand nid | 99 R$ | ✅ |
| `GiantNest` | Nid géant | 399 R$ | ✅ |
| `Followers3` | Escorte de dragons | 199 R$ | ✅ |
| `VIP` | 👑 VIP | 399 R$ | ✅ |
| `Aura` | Aura de dragon | 149 R$ | ✅ |
| `Wings` | Ailes de dragon | 249 R$ | 🔜 prochaine version |
| `Trainer` | Entraîneur | 349 R$ | 🔜 prochaine version |
| `DoubleEntry` | Double inscription | 249 R$ | 🔜 prochaine version |

Ne crée pas encore les passes marqués 🔜 : leur effet n'existe pas encore. Ils
restent affichés « Bientôt » dans la boutique.

### 2. Créer les Developer Products
**Monetization → Developer Products** → **Create a Developer Product** :

| Clé dans le code | Nom | Prix conseillé | Effet codé |
|---|---|---|---|
| `StarterPack` | Pack du débutant | 49 R$ | ✅ |
| `LuckPotion` | Potion de chance x3 | 49 R$ | ✅ |
| `GoldPotion` | Potion d'or x3 | 49 R$ | ✅ |
| `GoldSmall` | Petit sac d'or | 25 R$ | ✅ |
| `GoldMedium` | Sac d'or | 99 R$ | ✅ |
| `GoldHuge` | Coffre d'or | 399 R$ | ✅ |
| `UnlockZone` | Débloquer la zone suivante | 149 R$ | ✅ |
| `RoyalEgg`, `CosmicEgg`, `MeteorShower` | | | 🔜 version 2 |

### 3. Coller les IDs
Copie l'**ID** de chaque objet (le grand nombre) et colle-le dans
`src/shared/Monetization.luau` à la place du `Id = 0` correspondant. La
boutique affiche alors le vrai prix et le bouton « Acheter ».

### Ajouter un nouveau Game Pass
1. Ajoute une ligne dans `Monetization.GamePasses` (copie une ligne existante).
2. Code son effet là où il agit : par exemple `MonetizationService.HasPass(player, "MaClé")`
   dans `EconomyService` pour un bonus d'or. Demande-moi, je le code.

---

## 🎨 Remplacer la carte et les dragons (dans Studio)

### Ta propre carte
Construis tes îles dans Studio, puis crée un dossier **workspace → Map** avec :
- `Map/Eggs/Prairie`, `Map/Eggs/Volcan`, … : une Part (l'œuf) par zone
- `Map/Gates/Volcan`, `Map/Gates/Ocean`, … : la barrière de chaque zone (pas pour la Prairie)
- `Map/Spawns/Prairie`, … : où arrive le joueur qui se téléporte (facultatif)

Les noms des zones sont dans `Zones.luau` : `Prairie`, `Volcan`, `Ocean`, `Ciel`, `Neant`.
Dès que le dossier `Map` existe, la carte générée en code n'est plus créée.

### Tes propres modèles de dragons
Crée un dossier **ReplicatedStorage → DragonModels** et mets-y un modèle par
espèce, nommé comme dans `Dragons.luau` (`PrairieCommun`, `VolcanEpique`…).
Le jeu les utilise à la place des dragons construits en code.

### Les sons
Choisis des sons gratuits dans la **Toolbox → Audio** de Studio, copie leur ID
et colle-le dans `Config.Sounds` sous la forme `"rbxassetid://ID"`.

---

## 🗺️ La suite

Voir [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md), partie « Les étapes ».
