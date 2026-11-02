# 🎮 Pipeline Godot 4 HD-2D & Kitbashing Éclairé (Zéro Euro)

Bienvenue dans le **dossier de configuration et starter-kit** du projet de jeu vidéo fondé sur l'approche **HD-2D et Kitbashing éclairé**, entièrement orchestré par des agents IA et financé par vos accès étudiants et quotas gratuits.

---

## 🌟 Philosophie du Pipeline
L'approche **HD-2D & Kitbashing Éclairé** résout le goulot d'étranglement de la création d'assets 3D pour un développeur solo :
1. **Géométrie 3D Modulaire Simple :** Des blocs, sols, piliers et ruines issus de packs libres (KayKit / Kenney) ou générés à la volée par Flux + Microsoft Trellis 2.
2. **Éclairage 3D Moderne Sublimé :** Le moteur Godot 4 (Forward+) applique en temps réel l'occlusion ambiante (SSAO), la lumière rasante volumétrique (Volumetric Fog), la lueur (Glow/Bloom) et le tonemapping cinématique (ACES).
3. **Sprites 2D Billboards Rétro :** Des personnages et monstres en sprites pixel-art orientés vers la caméra avec shaders d'ombre et de contour.
4. **Pilotage Agentique Total :** Google Antigravity, les serveurs MCP Godot, et les complétions Copilot/Continue génèrent le code, les nœuds de scène et les shaders sans friction.

---

## 🗂️ Structure du Dossier de Projet

```text
godot-hd2d-pipeline/
├── project.godot                  # Configuration moteur Godot 4 (Forward+, Pixel Filter, Ombres 4K)
├── icon.svg                       # Icône vectorielle du projet
├── .env.example                   # Modèle de variables pour toutes vos clés gratuites (Groq, Gemini, etc.)
├── .gitignore                     # Exclusion des caches (.godot/) et clés d'API
│
├── config/                        # Configurations des outils et ponts IA
│   ├── continue_config.json       # Config pour l'extension Continue (Gemini 1.5 Pro/Flash)
│   ├── godot_mcp_config.json      # Config du serveur MCP Godot pour Antigravity
│   └── godot_bridge_server.py     # Script Python pour inspecter le projet et valider les scènes
│
├── scenes/                        # Scènes Godot 4 (.tscn) et environnements (.tres)
│   ├── world_environment.tres     # Éclairage 3D moderne (SSAO, Brouillard Volumétrique, Glow)
│   └── main_hd2d_scene.tscn       # Scène HD-2D complète (Joueur, Caméra 2.5D, Kitbash, PNJ)
│
├── scripts/                       # Scripts GDScript typés et optimisés
│   ├── camera/
│   │   └── hd2d_camera.gd         # Caméra plongeante fluide (Octopath Traveler style + Screen Shake)
│   ├── player/
│   │   └── player_hd2d.gd         # Contrôleur 2.5D (CharacterBody3D + orientation sprite)
│   └── ai/
│       └── groq_npc_dialogue.gd   # Dialogue temps réel avec PNJ via Groq Cloud (Llama 3.3)
│
├── shaders/                       # Shaders Godot 4 prêts à l'emploi
│   ├── sprite_billboard_hd2d.gdshader # Billboard Y-axis avec ombre 3D et contour pixel
│   ├── stylized_water.gdshader    # Eau stylisée avec écume de contact et dégradé de profondeur
│   └── palette_postprocess.gdshader   # Étalonnage colorimétrique rétro et vignettage doux
│
├── prompts/                       # Bibliothèque de prompts pour générer vos assets gratuitement
│   ├── trellis_flux_pipeline.md   # Guide complet : Image Flux 2D -> Modèle 3D GLB via Trellis 2
│   ├── elevenlabs_sfx.md          # Prompts d'effets sonores et ambiances (ElevenLabs & Stable Audio)
│   └── npc_dialogue_templates.json# Personas et prompts système pour PNJ interactifs
│
├── docs/                          # Spécifications et gestion de projet
│   ├── GDD_TEMPLATE.md            # Modèle de Game Design Document pour Notion Education
│   └── STUDENT_PERKS_GUIDE.md     # Tableau complet de vos accès étudiants (GitHub, Azure, JetBrains...)
│
└── assets/                        # Répertoires dédiés aux ressources
    ├── models/                    # Objets 3D modulaires (.glb, .gltf)
    ├── sprites/                   # Sprites 2D pixel-art (.png)
    ├── audio/                     # Effets sonores et bandes son (.wav, .ogg)
    └── ui/                        # Icônes et thèmes d'interface
```

---

## ⚡ Démarrage Rapide

### 1. Télécharger Godot 4
Si Godot 4 n'est pas encore sur votre machine :
1. Téléchargez la version portable officielle gratuite : [Godot Engine 4.3 Stable (Windows 64-bit)](https://godotengine.org/download/windows/).
2. Décompressez l'exécutable (ex: dans `C:\Program Files\Godot\` ou sur votre bureau).
3. Ouvrez Godot, cliquez sur **Importer**, et sélectionnez le fichier `project.godot` situé dans ce dossier.

### 2. Configurer vos Clés d'API Gratuites
1. Copiez le fichier `.env.example` en `.env` :
   ```bash
   cp .env.example .env
   ```
2. Ajoutez votre clé gratuite **Google AI Studio** (`GEMINI_API_KEY`) et votre clé gratuite **Groq Cloud** (`GROQ_API_KEY`).

### 3. Tester la Scène de Base
Ouvrez directement la scène `scenes/main_hd2d_scene.tscn` dans Godot ou appuyez sur **F5** :
- Le personnage peut se déplacer dans l'arène 3D avec les touches directionnelles (ou ZQSD).
- La caméra HD-2D suit le joueur avec anticipation et amortissement.
- Le bassin d'eau stylisée ondule avec écume dynamique.
- L'éclairage directionnel rasant projette des ombres douces 4K avec occlusion ambiante (SSAO) et brume volumétrique.
- Le PNJ *Maître Eldrin* est prêt à recevoir vos messages et à y répondre via le script Groq.

---

## 🤖 Routine de Production avec Antigravity

1. **Étape quotidienne :** Décrivez à Antigravity la mécanique ou l'asset voulu (ex: *« Crée un système de coffre interactif avec shader de brillance et bruitage d'ouverture »*).
2. **Génération agentique :** L'agent écrit la scène `.tscn`, le script GDScript typé, et ajuste les paramètres d'inspecteur.
3. **Validation & Correction :** L'agent valide la scène et corrige toute erreur signalée dans la console de debug.
