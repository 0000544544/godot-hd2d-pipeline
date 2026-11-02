class_name NPCEldrin
extends StaticBody3D

## Contrôleur d'animation et d'orientation pour le PNJ Maître Eldrin (Mage)
## - Gère le bouclage automatique de l'animation d'attente (Idle)
## - Oriente par défaut le mage vers le bas de la cour (rotation_degrees.y = -20°)
## - Effectue une rotation fluide (lerp_angle) vers le Chevalier dès qu'il est à portée (< 5 m)

@export var anim_player: AnimationPlayer
@export var model_root: Node3D
@export var player_target: Node3D

@export_group("Orientation & Regard Dynamique")
@export var default_rotation_degrees: float = -20.0
@export var detection_range: float = 5.0
@export var rotation_speed: float = 3.5

var _default_rotation_rad: float = 0.0

func _ready() -> void:
	if not model_root and has_node("Mage"):
		model_root = get_node("Mage")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	# Bouclage forcé de l'animation Idle
	if anim_player and anim_player.has_animation("Idle"):
		var anim: Animation = anim_player.get_animation("Idle")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")
	
	_default_rotation_rad = deg_to_rad(default_rotation_degrees)
	if model_root:
		model_root.rotation.y = _default_rotation_rad

func _physics_process(delta: float) -> void:
	_update_gaze(delta)

## Oriente doucement le mage vers le joueur s'il est à portée, ou revient à la rotation par défaut
func _update_gaze(delta: float) -> void:
	if not model_root:
		return
	
	# Recherche automatique du joueur
	if not player_target or not is_instance_valid(player_target):
		player_target = get_node_or_null("../Player")
		if not player_target:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player_target = players[0]
	
	var target_rot_y: float = _default_rotation_rad
	
	if player_target and is_instance_valid(player_target):
		var to_player: Vector3 = player_target.global_position - global_position
		to_player.y = 0.0
		var distance: float = to_player.length()
		
		# Si le joueur est à moins de detection_range (5 mètres)
		if distance <= detection_range and distance > 0.05:
			# Calcule l'angle orienté vers le joueur
			target_rot_y = atan2(to_player.x, to_player.z)
	
	# Interpolation angulaire douce pour éviter tout à-coup
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rot_y, rotation_speed * delta)
