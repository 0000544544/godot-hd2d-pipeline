# 📜 Game Design Document (GDD) - Template HD-2D Zero Euro

Ce document sert de référence centrale pour structurer la vision, les mécaniques, l'art et les tâches dans Notion Education et guider vos sessions de programmation avec Antigravity.

---

## 1. Vision & Piliers du Jeu
* **Titre Provisoire :** Project Chrono-Kitbash (ou votre titre)
* **Genre :** Action-RPG / Exploration HD-2D (2.5D)
* **Cible Visuelle :** Esthétique Octopath Traveler / Triangle Strategy (Kitbashing 3D géométrique + éclairage PBR cinématique + sprites 2D en billboard).
* **Piliers de Gameplay :**
  1. *Exploration Tactile :* Monde 3D isométrique riche en verticalité et détails.
  2. *PNJ Vivants :* Dialogues générés en temps réel par LLM léger (Groq Cloud).
  3. *Fluidité & Zéro Frustration :* Contrôles réactifs et feedback visuel/sonore soigné.

---

## 2. Direction Artistique & Kitbashing
* **Géométrie 3D de base :** Packs modulaires KayKit / Kenney (sols de dalles, piliers de ruines, coffres, ponts).
* **Objets Héroïques (Hero Assets) :** Concepts 2D générés par Flux convertis en maillages 3D via Microsoft Trellis 2.
* **Personnages & Ennemis :** Sprites pixel-art 2D (billboards verticaux avec shader de contour et ombre portée dynamique).
* **Éclairage & Ambiance :**
  - WorldEnvironment Godot 4 (SSAO, Brouillard volumétrique, Glow, Tonemap ACES).
  - Éclairage solaire rasant (DirectionalLight3D dorée) et torches dynamiques (OmniLight3D avec lueur vacillante).

---

## 3. Architecture Technique (Zero Euro Stack)
* **Moteur :** Godot 4.3 (Forward+)
* **Contrôleur IA :** Antigravity + Godot MCP (`godot-ai`) + Continue (Google AI Studio Gemini 1.5 Flash/Pro)
* **Audio :** ElevenLabs Sound Effects (effets d'action) + Web Audio / Stable Audio Open (ambiances)
* **Backend & Sauvegardes :** Supabase (PostgreSQL + pgvector) / Appwrite Cloud Education
* **Monitoring :** Sentry for Games

---

## 4. Backlog de Production (Kanban Notion)
- [x] Initialisation du squelette de projet Godot 4
- [x] Configuration du WorldEnvironment 3D et éclairage moderne
- [x] Écriture des shaders HD-2D (billboard, eau stylisée, étalonnage)
- [x] Implémentation du contrôleur de joueur 2.5D et de la caméra fluide
- [ ] Import des premiers assets modulaires KayKit / Kenney
- [ ] Branchement du serveur Godot MCP pour contrôle agentique direct
- [ ] Premier test de dialogue en temps réel avec le PNJ via Groq Cloud
