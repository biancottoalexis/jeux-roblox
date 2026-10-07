# ⚔️ Jeu de combat anime (Roblox)

Un jeu de combat inspiré des animés japonais. Les joueurs tirent un **style de
combat** (Flamme, Foudre, Ombre, Soleil…), se battent avec des combos et des
compétences, gagnent des Yens et de l'XP, et peuvent acheter des avantages en
Robux.

## Ce qui est déjà fait

| Système | Détails |
|---|---|
| **Combat** | Combo de 4 coups (clic gauche), garde (F), esquive (Q), étourdissement, recul, chiffres de dégâts |
| **Styles** | 6 styles de 4 raretés, avec 4 compétences chacun (Z, X, C, V) |
| **Progression** | Niveaux, XP, Yens. Les compétences se débloquent aux niveaux 1, 5, 15 et 30 |
| **Spins** | Tirage aléatoire d'un style, avec des chances qui dépendent de la rareté |
| **Sauvegarde** | Données sauvegardées automatiquement (DataStore) |
| **Monétisation** | Game Passes (VIP x2 Yens, XP x2) et Developer Products (Spins, Yens) |
| **Mannequins** | 3 mannequins pour s'entraîner seul |
| **Interface** | Infos joueur, barre de vie, compétences avec temps de recharge, boutique |
| **Contrôles** | PC, manette et mobile (boutons tactiles automatiques) |

## Structure du projet

```
default.project.json       ← configuration Rojo (relie le code à Studio)
src/
  shared/                  → ReplicatedStorage.Shared (lu par serveur ET client)
    Config.luau            ← ⚙️ équilibrage : dégâts, vitesses, récompenses
    Styles.luau            ← 🔥 les styles et leurs compétences
    Monetization.luau      ← 💰 IDs des Game Passes / Products
    Remotes.luau, Movement.luau
  server/                  → ServerScriptService (code secret, anti-triche)
    Services/
      CombatService        ← tout le combat
      DataService          ← sauvegarde
      ProgressionService   ← niveaux, récompenses, spins
      MonetizationService  ← achats Robux
      DummyService         ← mannequins
      Effects              ← effets visuels
  client/                  → StarterPlayerScripts (ce que voit le joueur)
    HUD, Input, Animations, State
```

Les fichiers que tu modifieras le plus souvent sont **Config**, **Styles** et
**Monetization**. Ce sont surtout des chiffres et des noms, sans logique compliquée.

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
| Z / X / C / V | Compétences |

Pour tester à plusieurs : onglet **Test** → **Clients and Servers** → 2 joueurs → **Start**.

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
   « 5 000 Yens ».
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
2. **Les spins font vendre.** Dans les jeux anime, les tirages de styles rares
   sont la source principale de revenus. Garde les styles légendaires vraiment
   rares (actuellement 2 %).
3. **Ne vends pas la victoire.** Les joueurs détestent les jeux « pay-to-win ».
   Vends du confort (x2, plus de spins), pas des dégâts énormes.
4. **Mises à jour régulières.** Un nouveau style toutes les 1 à 2 semaines fait
   revenir les joueurs.
5. **Pub.** Fais des vidéos TikTok ou YouTube Shorts des compétences les plus
   impressionnantes. Fais aussi de la pub dans Roblox (Ads Manager).

---

## ➕ Ajouter un nouveau style

Ouvre `src/shared/Styles.luau`, copie un style existant, change son nom, sa
couleur, sa rareté et ses compétences, puis ajoute son identifiant dans
`Styles.Order`. C'est tout. Les types de compétences disponibles sont décrits en
haut du fichier.

## 🎬 Ajouter des animations

1. Dans Studio, **Avatar → Animation Editor** (ou le plugin Moon Animator).
2. Anime un coup de poing, puis **Publish to Roblox** et copie l'ID.
3. Colle-le dans `Config.Animations` sous la forme `"rbxassetid://ID"`.

Voir [docs/ROADMAP.md](docs/ROADMAP.md) pour la suite du projet.
