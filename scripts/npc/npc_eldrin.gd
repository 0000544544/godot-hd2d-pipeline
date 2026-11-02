class_name NPCEldrin
extends StaticBody3D

## Contrôleur d'animation pour le PNJ Maître Eldrin (Mage)
## Configure le bouclage automatique de l'animation d'attente

@export var anim_player: AnimationPlayer
@export var model_root: Node3D

func _ready() -> void:
	if not model_root and has_node("Mage"):
		model_root = get_node("Mage")
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	if anim_player and anim_player.has_animation("Idle"):
		var anim: Animation = anim_player.get_animation("Idle")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")
