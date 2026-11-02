# 🔊 Pipeline Audio Zéro Euro : ElevenLabs & Stable Audio Open

Ce guide liste les prompts optimisés pour générer vos effets sonores (SFX) et paysages sonores d'ambiance avec les quotas gratuits d'ElevenLabs Sound Effects et le modèle ouvert Stable Audio Open.

---

## 1. Effets d'Interface et Rétro HD-2D (ElevenLabs Sound Effects)
ElevenLabs excelle dans les sons d'action courts et percutants.

* **Validation Menu / UI Click :**
  ```text
  clean crisp UI menu click sound, gentle wooden and stone click, warm medieval RPG interface sound, subtle resonant chime
  ```
* **Ouverture de Coffre :**
  ```text
  heavy ancient stone chest opening, heavy friction slide, crumbling pebble debris, subtle golden magical glow sound
  ```
* **Impact de Coup (Combat HD-2D) :**
  ```text
  sharp sword slashing impact on leather armor, fast metallic slice with punchy low-end thud, stylized retro RPG hit sound
  ```
* **Saut / Atterrissage :**
  ```text
  leather boot landing firmly on packed dry dirt and cobblestone, light cloth rustle, short and punchy
  ```

---

## 2. Ambiances & Musiques de Fond (Stable Audio Open / Hugging Face)
Stable Audio Open (générable gratuitement sur Hugging Face Spaces ou avec vos 5h GPU Camber).

* **Sanctuaire Paisible (BGM d'ambiance) :**
  ```text
  peaceful ambient fantasy village, warm classical acoustic guitar and subtle wooden flute melody, gentle wind breeze, distant church bell chime, 85 bpm, warm relaxing atmosphere
  ```
* **Donjon Ancien :**
  ```text
  dark ambient dungeon drone, eerie cavern echoes, distant water dripping on wet stone, low mystical frequency hum, tense atmosphere
  ```

---

## 3. Intégration Godot 4
- Placez les fichiers `.wav` ou `.ogg` dans `res://assets/audio/sfx/` ou `res://assets/audio/bgm/`.
- Utilisez `AudioStreamPlayer2D` / `AudioStreamPlayer3D` pour une spatialisation sonore réaliste dans le monde 2.5D.
