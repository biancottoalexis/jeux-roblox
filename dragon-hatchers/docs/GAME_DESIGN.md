# 🐉 Dragon Hatchers : le plan du jeu

Ce document décrit le jeu complet, pour savoir où on va. ✅ = déjà codé,
🔜 = prévu. Les chiffres sont des valeurs de départ, à ajuster après les tests.

## 1. Le jeu en bref
Tu élèves des dragons. Tu fais éclore des œufs, tes dragons produisent de
l'or, et tu **fusionnes 3 dragons identiques** pour en obtenir un plus fort.
Tu cherches les **mutations ultra rares** et tu envoies ton meilleur dragon
combattre dans l'**Arène** devant tout le serveur.

**Pour qui** : les joueurs Roblox de 9 à 16 ans qui aiment collectionner,
avoir des objets rares et se montrer.

**Objectif** : un jeu qui rapporte. Les joueurs gratuits peuvent tout faire,
plus lentement ; les Robux font aller plus vite et donnent des dragons rares à montrer.

## 2. Le monde : 5 îles ✅
| Zone | Élément | Débloquer | Œuf |
|---|---|---|---|
| 🌿 Prairie | Nature | Gratuit | 50 🪙 |
| 🌋 Volcan | Feu | 2 500 🪙 | 5 000 🪙 |
| 🌊 Océan glacé | Eau | 75 000 🪙 | 150 000 🪙 |
| ⚡ Royaume du Ciel | Foudre | 2,5 M 🪙 | 5 M 🪙 |
| 🌌 Néant cosmique | Cosmique | 100 M 🪙 | 200 M 🪙 |

🔜 Une nouvelle zone toutes les 2 à 3 semaines après la sortie.

## 3. Les dragons ✅
- **Rareté** : Commun 60 % (x1), Rare 30 % (x3), Épique 9 % (x10), Légendaire 1 % (x40).
- **Mutations** : Doré 1/50 (x3), Arc-en-ciel 1/500 (x10), Cosmique 1/10 000 (x50).
- **Fusion** : 3 identiques → niveau suivant (x4), niveaux 1 à 5, 2 % de chance d'améliorer la mutation.
- **Nid** : 12 places, agrandissable à 30 avec de l'or, +10 et +25 avec les Game Passes.
- Le meilleur dragon vole derrière le joueur (3 avec un Game Pass).

## 4. La boucle de jeu
1. ✅ Récolter : production chaque seconde + bouton « Récolter ».
2. ✅ Ouvrir des œufs (animation d'éclosion).
3. ✅ Fusionner.
4. ✅ Débloquer l'île suivante.
5. ✅ Gains hors ligne : 8 h à 50 % (24 h à 100 % avec le Game Pass).
6. 🔜 **Renaissance** (dès le Royaume du Ciel) : on repart de zéro avec des
   Écailles de renaissance (+50 % d'or chacune, pour toujours). Les dragons
   achetés en Robux sont gardés.

## 5. Les événements 🔜
- **☄ Pluie de météores, toutes les 15 minutes** : 60 secondes, des œufs rares
  tombent partout, le premier qui touche gagne. Mutations x2 pendant la pluie.
- **⚔ Arène des dragons, toutes les heures** : tournoi automatique, la force
  dépend de la rareté, du niveau, de la mutation et de 20 % de chance. Les
  éléments comptent (Feu > Nature > Eau > Feu, +25 %). Le gagnant reçoit un
  œuf rare et une couronne jusqu'au tournoi suivant.

## 6. Ce qui fait revenir 🔜
- Récompense de connexion sur 7 jours (le jour 7 donne un œuf rare).
- 3 quêtes par jour (« Fusionne 10 dragons », « Ramasse 5 œufs de météore »…).
- Classement mondial : plus gros nid, nombre de Cosmiques, victoires à l'Arène.
- Codes promo à partager sur TikTok.
- Échange de dragons entre joueurs (double confirmation contre les arnaques).

## 7. La boutique
- ✅ **23 Game Passes** (20 déjà fonctionnels) : voir le README pour la liste et les prix.
- ✅ **Developer Products** : pack du débutant, potions, sacs d'or, déblocage de zone.
- 🔜 Œuf Royal (dragons exclusifs), Œuf Cosmique, pluie de météores payante.
- 🔜 **Passe de saison** mensuel (gratuit + premium à 499 R$).
- 🔜 **Pack Ultime** : tous les Game Passes à -40 % (environ 4 999 R$).
- 🔜 **Offrir à un ami** : acheter un Game Pass pour quelqu'un.
- 🔜 **Offre du jour** : un Game Pass à -30 %, différent chaque jour.
- ✅ **Offres au bon moment** : nid plein, beaucoup d'œufs, beaucoup de
  fusions, presque assez d'or pour la zone suivante, pack du débutant.

**Règles à respecter** : les chances des tirages payants sont toujours
affichées, pas de fausses promotions, un joueur gratuit peut toujours avancer.

## 8. Qui fait quoi
| Claude (le code) | Toi (dans Roblox Studio) |
|---|---|
| Œufs, chances, fusion, mutations | Les îles (Toolbox, ou garde la carte générée pour commencer) |
| Or, production, gains hors ligne | Les modèles de dragons (Toolbox, Blender…) |
| Sauvegarde, boutique, offres | L'icône et les images du jeu |
| Événements, quêtes, classements | Les sons et la musique |
| Toute l'interface | Les tests avec tes potes |

## 9. Les étapes
1. ✅ **Version 1, le cœur du jeu** : îles, œufs, mutations, fusion, or,
   nid, sauvegarde, boutique complète, offres, gains hors ligne.
2. 🔜 **Version 2, l'addiction** : pluie de météores, Œuf Royal et Œuf Cosmique,
   codes promo, récompense du jour. **On publie.**
3. 🔜 **Version 3, la profondeur** : renaissance, Arène, quêtes, classement,
   passe de saison.
4. 🔜 **Version 4, le social** : échange de dragons, offrir à un ami,
   événements de saison (Halloween, Noël), un nouveau dragon chaque semaine.

## 10. Le lancement
1. Faire tester à 5 ou 10 potes et corriger ce qui ennuie.
2. Une belle icône (un dragon Cosmique qui sort de son œuf), 3 vidéos TikTok
   de mutations rares, des codes promo.
3. Un peu de pub dans Roblox (Ads Manager), un Discord, une mise à jour par semaine.
