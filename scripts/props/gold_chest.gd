class_name GoldChest
extends Node3D

## Contrôleur pour le coffre doré :
## - Détecte l'appui sur [E] via le composant Interactable
## - Déclenche la rotation d'ouverture du couvercle (-65°)
## - Libère une lueur dorée avec éclat lumineux
## - Désactive l'invite d'interaction pour empêcher toute réouverture
## - Émet un signal chest_opened et maintient la variable accessible is_opened

signal chest_opened()

@export var interactable: Area3D
@export var open_angle: float = -65.0
@export var open_duration: float = 0.6

var is_opened: bool = false
var _lid_node: Node3D = null
var _glow_light: OmniLight3D = null

func _ready() -> void:
	add_to_group("gold_chest")
	_lid_node = find_child("chest_gold_lid", true, false)
	
	if not interactable:
		interactable = find_child("InteractableArea", true, false) as Area3D
	
	if interactable:
		interactable.prompt_text = "[E] Ouvrir"
		interactable.prompt_offset = Vector3(0, 1.25, 0)
		interactable.interacted.connect(_on_interacted)

func _on_interacted(_player: Node3D) -> void:
	if is_opened:
		return
	open_chest()

func open_chest() -> void:
	if is_opened:
		return
	is_opened = true
	chest_opened.emit()
	
	# Récompenser le joueur avec le trésor royal (+100 Or)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_gold"):
		player.add_gold(100)
	
	if not interactable:
		interactable = find_child("InteractableArea", true, false)
	
	# Désactiver immédiatement l'invite d'interaction
	if interactable and interactable.has_method("set_active"):
		interactable.set_active(false)
	
	# Rotation fluide du couvercle vers l'arrière
	if _lid_node:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(_lid_node, "rotation_degrees:x", open_angle, open_duration)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
	
	# Lueur dorée émergeant du coffre
	_spawn_golden_glow()

func _spawn_golden_glow() -> void:
	_glow_light = OmniLight3D.new()
	_glow_light.light_color = Color(1.0, 0.85, 0.35, 1.0)
	_glow_light.light_energy = 0.0
	_glow_light.omni_range = 5.5
	_glow_light.omni_attenuation = 1.2
	_glow_light.position = Vector3(0, 0.55, 0)
	add_child(_glow_light)
	
	var tween = create_tween()
	# Éclat initial puis stabilisation douce
	tween.tween_property(_glow_light, "light_energy", 3.2, 0.25)
	tween.tween_property(_glow_light, "light_energy", 1.8, 0.6)
