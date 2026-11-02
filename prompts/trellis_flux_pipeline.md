# 🎨 Pipeline Visuel Zéro Euro : Flux -> Trellis 2 -> Godot 4

Ce guide détaille la méthode pour générer des assets 3D optimisés pour le Kitbashing HD-2D sans dépenser un seul centime, en exploitant les espaces gratuits Hugging Face et l'IA générative.

---

## Étape 1 : Génération du Concept 2D avec Flux (Hugging Face Spaces)
* **Outil :** Flux.1 [schnell] ou [dev] via les Spaces Hugging Face gratuits (ex: `black-forest-labs/FLUX.1-schnell`).
* **Objectif :** Obtenir une vue isométrique ou orthogonale nette de l'objet sur fond uni (gris neutre ou blanc) sans ombre portée complexe.

### Structure du Prompt Recommandé pour Trellis :
```text
3D game asset, stylized fantasy stone chest with glowing runic carvings, low-poly kitbash style, isometric view, centered, clean solid light gray background (#808080), sharp focus, professional 3D render style, no ground shadow, no background clutter
```

### Règles Clés pour le Prompt 2D :
1. **Fond uni impératif :** Préciser systématiquement `solid plain neutral gray background`. Trellis segmente mieux les silhouettes sur fond neutre.
2. **Perspective 3/4 :** Demander `isometric 3/4 view` pour que Trellis infère la profondeur arrière.
3. **Style géométrique clair :** Mentionner `stylized`, `clean geometry`, `kitbash modular piece`.

---

## Étape 2 : Conversion 2D vers 3D via Microsoft Trellis 2
* **Outil :** Espace Hugging Face Trellis / Trellis 2 (ou instance locale/Camber GPU).
* **Entrée :** L'image 2D générée à l'étape 1 (détourée si nécessaire via `rembg` gratuit).
* **Sortie :** Fichier `.glb` ou `.gltf` texturé.

### Paramètres d'Extraction Recommandés :
- **Target Face Count (Décimation) :** 1 500 à 4 000 polygones (optimisé pour le temps réel).
- **Texture Resolution :** 1024x1024 (suffisant en HD-2D car sublimé par l'éclairage de Godot).
- **Format d'export :** `GLB (Binary glTF)`.

---

## Étape 3 : Import et Intégration dans Godot 4
1. Déposez le fichier `.glb` dans le dossier `res://assets/models/`.
2. Double-cliquez sur l'asset dans le dock `Fichiers` de Godot pour ouvrir les paramètres d'import :
   - Cochez **Import as MeshLibrary** si vous l'ajoutez à une GridMap (tileset 3D).
   - Dans `Materials`, choisissez **Keep on Re-import** pour conserver vos ajustements PBR (Roughness, Metallic).
3. Glissez le nœud dans votre scène sous le nœud `GeometryKitbash`.
4. Grâce au `WorldEnvironment.tres`, l'objet reçoit automatiquement l'occlusion ambiante (SSAO), la lumière directionnelle dorée et le brouillard volumétrique !
