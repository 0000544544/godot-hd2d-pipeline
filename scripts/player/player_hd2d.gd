class_name PlayerHD2D
extends CharacterBody3D

## Contrôleur de Joueur 3D HD-2D avec AnimationPlayer
## Déplacement supportant nativement ZQSD (AZERTY), WASD (QWERTY), flèches et manette.

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
	# Recherche automatique du modèle et de l'AnimationPlayer
	if not model_root and has_node("Knight"):
		model_root = get_node("Knight")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	_play_anim("Idle")

func _physics_process(delta: float) -> void:
	# Application de la gravité
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Gestion du saut (Espace ou bouton manette)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		_play_anim("Jump_Start")

	# Lecture des inputs de déplacement : ZQSD prioritaire + WASD + Flèches + Joystick
	var input_dir: Vector2 = _get_input_direction()
	var move_dir: Vector3 = Vector3(input_dir.x, 0.0, input_dir.y)

	var speed = move_speed
	var is_moving = move_dir.length_squared() > 0.01

	if is_moving:
		velocity.x = move_toward(velocity.x, move_dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, move_dir.z * speed, acceleration * delta)

		# Rotation fluide du modèle 3D vers la direction de course
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

	# Animation en l'air (chute)
	if not is_on_floor() and velocity.y < 0:
		_play_anim("Jump_Idle")

	move_and_slide()

## Récupère le vecteur de déplacement en gérant ZQSD, WASD, flèches et stick analogique
func _get_input_direction() -> Vector2:
	var dir: Vector2 = Vector2.ZERO

	# Touches ZQSD (AZERTY) et WASD (QWERTY)
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1.0

	# Support du stick analogique de la manette
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	return dir.normalized()

func _play_anim(anim_name: String, blend_time: float = 0.15) -> void:
	if not anim_player:
		return
	if _current_anim == anim_name:
		return
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name, blend_time)
		_current_anim = anim_name
