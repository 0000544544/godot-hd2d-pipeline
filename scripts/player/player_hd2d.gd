class_name PlayerHD2D
extends CharacterBody3D

## Contrôleur de Joueur 3D HD-2D avec AnimationPlayer
## Déplacement 3D fluide, rotation du modèle vers la trajectoire et gestion des animations

@export_group("Mouvement")
@export var move_speed: float = 6.0
@export var sprint_multiplier: float = 1.35
@export var acceleration: float = 30.0
@export var friction: float = 25.0
@export var rotation_speed: float = 12.0
@export var jump_velocity: float = 7.5

@export_group("Modèle 3D & Animation")
@export var model_root: Node3D
@export var anim_player: AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * 2.2
var _current_anim: String = ""

func _ready() -> void:
	# Recherche automatique si non assigné dans l'inspecteur
	if not model_root and has_node("Knight"):
		model_root = get_node("Knight")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	_play_anim("Idle")

func _physics_process(delta: float) -> void:
	# Application de la gravité
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Gestion du saut
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		_play_anim("Jump_Start")

	# Lecture des inputs de déplacement (ZQSD ou Flèches)
	var input_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var move_dir: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	var speed = move_speed
	var is_moving = move_dir.length_squared() > 0.01

	if is_moving:
		velocity.x = move_toward(velocity.x, move_dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * speed, acceleration * delta)

		# Rotation fluide du maillage 3D vers la direction de course
		if model_root:
			var target_rot_y = atan2(move_dir.x, move_dir.z)
			model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rot_y, rotation_speed * delta)

		if is_on_floor():
			_play_anim("Running_A")
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * delta)

		if is_on_floor() and velocity.y <= 0.01:
			_play_anim("Idle")

	# Animation en l'air
	if not is_on_floor() and velocity.y < 0:
		_play_anim("Jump_Idle")

	move_and_slide()

func _play_anim(anim_name: String, blend_time: float = 0.15) -> void:
	if not anim_player:
		return
	if _current_anim == anim_name:
		return
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend_time)
		_current_anim = anim_name
