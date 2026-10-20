# 📖 Jeu de magie et de grimoires (Roblox)

Un jeu de combat magique inspiré de **Black Clover**. Chaque joueur reçoit un
**grimoire** qui lui donne un attribut magique (Feu, Vent, Eau, Foudre, Glace,
Lumière, Ombre… ou le très rare Grimoire du Néant). Les joueurs se battent avec
des combos et des sorts qui consomment du mana, gagnent de l'or et de l'XP, et
peuvent acheter des avantages en Robux.

## ⚠️ Droits d'auteur : à lire

Black Clover appartient à son auteur et à ses éditeurs (Shueisha). Un jeu
**monétisé** qui utilise le nom « Black Clover », les noms des personnages
(Asta, Yuno…), des ordres de chevaliers ou des images de l'anime peut être
**supprimé par Roblox** après une plainte DMCA. Tu perdrais alors le jeu et tes
revenus.

La règle suivie ici est celle des grands jeux Roblox du même genre : on garde
l'**ambiance et les mécaniques** (grimoires, attributs magiques, mana, magie qui
annule les autres, ordres de chevaliers), mais avec **nos propres noms**.

- ✅ « Magie de Feu », « Grimoire du Néant », « Ordre du Loup Écarlate »… des noms à toi
- ✅ Dans la description du jeu : « inspiré des animés de magie »
- ❌ « Black Clover » dans le titre, les noms et les images des personnages, le logo

## Ce qui est déjà fait

| Système | Détails |
|---|---|
| **Combat** | Combo de 4 coups (clic gauche), garde (F), esquive (Q), étourdissement, recul, chiffres de dégâts |
| **Grimoires** | 8 attributs magiques de 4 raretés, avec 4 sorts chacun (Z, X, C, V) |
| **Mana** | Chaque sort coûte du mana. Il se recharge seul et en frappant, et augmente avec le niveau |
| **Progression** | Niveaux, XP et or. Les sorts se débloquent aux niveaux 1, 5, 15 et 30 |
| **Tirages** | Bouton « 📖 Grimoire » : tire un grimoire au hasard. Le Néant n'a que 1 % de chance |
| **Sauvegarde** | Données sauvegardées automatiquement (DataStore) |
| **Monétisation** | Game Passes (VIP x2 or, XP x2) et Developer Products (tirages, or) |
| **Mannequins** | 3 mannequins pour s'entraîner seul |
| **Récompense du jour** | Un cadeau à chaque connexion (7 jours, de plus en plus gros). Un jour manqué = retour au jour 1 |
| **Quêtes du jour** | 3 quêtes tirées au hasard chaque jour à minuit (UTC) : mannequins, kills, sorts, dégâts, boss |
| **Ordres de chevaliers** | 6 ordres à rejoindre dès le niveau 3, chacun avec sa couleur, son équipe et son bonus. Changer d'ordre coûte 2 000 or |
| **Classement mondial** | Top 10 par niveau, par kills, et classement des ordres selon leur mérite |
| **Boss** | Le Démon des Abysses apparaît toutes les 30 minutes. Tous ceux qui l'ont assez frappé gagnent de l'or et de l'XP, le meilleur gagne un tirage |
| **Interface** | Infos joueur, barres de vie et de mana, sorts avec temps de recharge, boutique, quêtes, ordres, classement, barre du boss |
| **Contrôles** | PC, manette et mobile (boutons tactiles automatiques) |

## Structure du projet

```
default.project.json       ← configuration Rojo (relie le code à Studio)
src/
  shared/                  → ReplicatedStorage.Shared (lu par serveur ET client)
    Config.luau            ← ⚙️ équilibrage : dégâts, vitesses, récompenses, boss
    Grimoires.luau         ← 📖 les grimoires et leurs sorts
    Orders.luau            ← ⚔ les ordres de chevaliers et leurs bonus
    Quests.luau            ← 📜 quêtes du jour et récompenses quotidiennes
    Monetization.luau      ← 💰 IDs des Game Passes / Products
    Remotes.luau, Movement.luau
  server/                  → ServerScriptService (code secret, anti-triche)
    Services/
      CombatService        ← tout le combat
      DataService          ← sauvegarde
      ProgressionService   ← niveaux, récompenses, tirages
      MonetizationService  ← achats Robux
      QuestService         ← quêtes et récompense du jour
      OrderService         ← ordres de chevaliers et mérite
      LeaderboardService   ← classement mondial
      BossService          ← le démon et son IA
      DummyService         ← mannequins
      Effects              ← effets visuels
  client/                  → StarterPlayerScripts (ce que voit le joueur)
    HUD, Input, Animations, State
    UI                     ← outils pour créer l'interface
    QuestMenu, OrderMenu, LeaderboardMenu, BossBar
```

Les fichiers que tu modifieras le plus souvent sont **Config**, **Grimoires**,
**Orders**, **Quests** et **Monetization**. Ce sont surtout des chiffres et des noms, sans logique compliquée.

---

## 🚀 Installation (débutant, environ 30 minutes)

### 1. Installer les outils

1. **Roblox Studio** : https://create.roblox.com → « Commencer à créer ».
2. **Visual Studio Code** : https://code.visualstudio.com. C'est l'éditeur de code.
3. Dans VS Code, ouvre l'onglet **Extensions** (Ctrl+Shift+X) et installe :
   - **Rojo – Roblox Studio Sync** (installe aussi le programme Rojo)
   - **Luau Language Server** (corrige les erreurs pendant que tu écris)
4. **Git** : https://git-scm.com (pour récupérer ce projet).

### 2. Récupérer le projet

```bash
git clone https://github.com/biancottoalexis/jeux-roblox.git
```

Ouvre ensuite le dossier `jeux-roblox` dans VS Code (Fichier → Ouvrir le dossier).

### 3. Relier VS Code à Roblox Studio

1. Dans VS Code, appuie sur Ctrl+Shift+P, tape **Rojo: Open menu**, puis clique
   sur **Install Roblox Studio plugin**.
2. Ouvre Roblox Studio et crée un nouveau jeu à partir du modèle **Baseplate**.
3. Dans VS Code, ouvre **Rojo: Open menu** et clique sur **default.project.json** ▶️.
   Rojo démarre.
4. Dans Studio, ouvre l'onglet **Plugins** → **Rojo** → **Connect**.

Le code apparaît dans Studio. Chaque modification enregistrée dans VS Code est
copiée automatiquement dans Studio.

### 4. Tester

Clique sur **▶ Play** dans Studio. Tu dois voir l'interface et 3 mannequins.

| Touche | Action |
|---|---|
| Clic gauche | Attaque (combo de 4) |
| F (maintenir) | Garde |
| Q | Esquive |
| Z / X / C / V | Sorts (coûtent du mana) |

Pour tester à plusieurs : onglet **Test** → **Clients and Servers** → 2 joueurs → **Start**.

**Le boss** : en Studio, il apparaît 20 secondes après le début du test (au lieu
de 3 minutes sur un vrai serveur), à gauche de la zone d'apparition. Quand un
cercle rouge apparaît sous lui, éloigne-toi ou mets ta garde (F) !

**Les classements** ont besoin de l'accès aux API (étape 5). Sans lui, ils
montrent seulement les joueurs du serveur.

### 5. Activer la sauvegarde

1. **File → Publish to Roblox** : donne un nom au jeu.
2. **Home → Game Settings → Security** : active **Enable Studio Access to API Services**.

Tant que ce n'est pas fait, le jeu marche mais affiche un avertissement et ne
sauvegarde rien.

---

## 💰 Monétisation : comment gagner des Robux

### Créer les Game Passes et Developer Products

1. Va sur https://create.roblox.com/dashboard/creations et choisis ton jeu.
2. **Monetization → Passes** → **Create a Pass** : crée « VIP » et « XP x2 ».
   Mets-les en vente (Sale → prix en Robux).
3. **Monetization → Developer Products** → crée « 5 Spins », « 25 Spins » et
   « 5 000 pièces d'or ».
4. Copie l'**ID** de chaque objet, c'est le grand nombre affiché.
5. Colle chaque ID dans `src/shared/Monetization.luau` à la place du `0`.

La boutique affiche « Bientôt » tant que l'ID vaut 0, et le vrai prix une fois
configuré.

### Les autres sources de revenus Roblox

- **Premium Payouts** : Roblox te paie selon le temps que les abonnés Premium
  passent dans ton jeu. Tu n'as rien à configurer. Plus ton jeu retient les
  joueurs, plus tu gagnes.
- **DevEx** : convertit tes Robux en vrai argent. Conditions : au moins 13 ans,
  un compte vérifié et 30 000 Robux minimum.

### Conseils qui font la différence

1. **La rétention avant tout.** Un jeu qui garde les joueurs longtemps est mis
   en avant par l'algorithme. Récompenses quotidiennes, quêtes et classements
   aident beaucoup (voir la feuille de route).
2. **Les tirages font vendre.** Dans les jeux anime, les tirages de grimoires
   rares sont la source principale de revenus. Garde le Grimoire du Néant
   vraiment rare (actuellement 1 %).
3. **Ne vends pas la victoire.** Les joueurs détestent les jeux « pay-to-win ».
   Vends du confort (x2, plus de tirages), pas des dégâts énormes.
4. **Mises à jour régulières.** Un nouvel attribut magique toutes les 1 à 2
   semaines fait revenir les joueurs.
5. **Pub.** Fais des vidéos TikTok ou YouTube Shorts des compétences les plus
   impressionnantes. Fais aussi de la pub dans Roblox (Ads Manager).

---

## ➕ Ajouter un nouveau grimoire

Ouvre `src/shared/Grimoires.luau`, copie un grimoire existant, puis change son
nom, sa couleur, sa rareté, ses sorts et leur coût en mana. Ajoute ensuite son
identifiant dans `Grimoires.Order`. C'est tout. Les types de sorts disponibles
sont décrits en haut du fichier.

## ➕ Ajouter une quête ou un ordre

- **Quête** : dans `src/shared/Quests.luau`, ajoute une ligne dans `Quests.Pool`
  avec son texte, son type (`Kind`), son objectif (`Goal`) et sa récompense.
- **Récompense du jour** : modifie la liste `Quests.DailyRewards`.
- **Ordre** : dans `src/shared/Orders.luau`, copie un ordre, change son nom, sa
  couleur et son bonus, puis ajoute son identifiant dans `Orders.Order`.

## 🎬 Ajouter des animations

1. Dans Studio, **Avatar → Animation Editor** (ou le plugin Moon Animator).
2. Anime un coup de poing, puis **Publish to Roblox** et copie l'ID.
3. Colle-le dans `Config.Animations` sous la forme `"rbxassetid://ID"`.

Voir [docs/ROADMAP.md](docs/ROADMAP.md) pour la suite du projet.
