extends Camera3D

## Caméra HD-2D Inclinée à -35° avec Suivi Fluide du Joueur

@export var target_path: NodePath
@export var smooth_speed: float = 6.0
@export var follow_offset: Vector3 = Vector3(0.0, 5.8, 8.2)

var target: Node3D = null

func _ready() -> void:
	fov = 40.0
	rotation_degrees = Vector3(-35.0, 0.0, 0.0)
	
	if target_path:
		target = get_node_or_null(target_path)
	if not target:
		target = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not target:
		target = get_tree().get_first_node_in_group("player")
		if not target:
			return

	var target_pos = target.global_position + follow_offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)
	# Maintien strict de l'inclinaison isométrique HD-2D à -35°
	rotation_degrees = Vector3(-35.0, 0.0, 0.0)
