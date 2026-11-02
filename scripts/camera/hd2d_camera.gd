class_name HD2DCamera
extends Camera3D

## Caméra HD-2D / 2.5D de style Octopath Traveler
## Maintient un angle plongeant constant, suit la cible avec lissage et supporte le screen shake.

@export var target: Node3D
@export var follow_speed: float = 5.5
@export var camera_distance: float = 17.0
@export var pitch_angle_degrees: float = 32.0
@export var camera_height_offset: float = 0.8
@export var look_ahead_factor: float = 0.5

var _shake_strength: float = 0.0
var _shake_decay: float = 5.0
var _rng = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# Configuration de l'angle initial
	rotation_degrees.x = -pitch_angle_degrees
	rotation_degrees.y = 0.0
	rotation_degrees.z = 0.0

func _physics_process(delta: float) -> void:
	if not target:
		return

	# Calcul de la position désirée (isométrique / 2.5D fixe)
	var target_pos: Vector3 = target.global_position
	
	# Si la cible a une vitesse (ex: CharacterBody3D), anticipation de la trajectoire
	if "velocity" in target:
		var vel: Vector3 = target.velocity
		target_pos += Vector3(vel.x, 0.0, vel.z) * (look_ahead_factor * 0.1)

	var angle_rad = deg_to_rad(pitch_angle_degrees)
	var offset_y = sin(angle_rad) * camera_distance + camera_height_offset
	var offset_z = cos(angle_rad) * camera_distance

	var desired_pos = Vector3(target_pos.x, target_pos.y + offset_y, target_pos.z + offset_z)

	# Lissage fluide
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Gestion du Screen Shake
	if _shake_strength > 0.0:
		_shake_strength = lerpf(_shake_strength, 0.0, _shake_decay * delta)
		var shake_offset = Vector3(
			_rng.randf_range(-_shake_strength, _shake_strength),
			_rng.randf_range(-_shake_strength, _shake_strength),
			0.0
		)
		h_offset = shake_offset.x
		v_offset = shake_offset.y
	else:
		h_offset = 0.0
		v_offset = 0.0

## Déclenche une secousse d'écran d'intensité donnée (ex: lors d'un coup ou d'une explosion)
func add_trauma(strength: float) -> void:
	_shake_strength = clamp(_shake_strength + strength, 0.0, 2.0)
