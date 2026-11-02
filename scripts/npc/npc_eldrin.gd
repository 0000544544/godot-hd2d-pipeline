class_name NPCEldrin
extends StaticBody3D

## Contrôleur d'animation pour le PNJ Maître Eldrin (Mage)

@export var anim_player: AnimationPlayer
@export var model_root: Node3D

func _ready() -> void:
	if not model_root and has_node("Mage"):
		model_root = get_node("Mage")
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
