class_name PlayerHD2D
extends CharacterBody3D

## Contrôleur de Joueur 3D HD-2D avec Machine à États et Bouclage d'Animations
## Gère la locomotion fluide (ZQSD/WASD), l'inertie, le dash réactif, le saut,
## le coup d'épée (avec Dash-Attack et Dodge-Cancel) et les interactions.

enum State {
	IDLE,
	MOVE,
	JUMP,
	DASH,
	ATTACK,
	INTERACT
}

@export_group("Mouvement & Inertie")
@export var move_speed: float = 6.0
@export var acceleration: float = 28.0
@export var friction: float = 22.0
@export var rotation_speed: float = 14.0
@export var jump_velocity: float = 7.5

@export_group("Dash / Esquive")
@export var dash_speed: float = 15.0
@export var dash_duration: float = 0.28
@export var dash_cooldown: float = 0.65

@export_group("Modèle 3D & Animation")
@export var model_root: Node3D
@export var anim_player: AnimationPlayer

var current_state: State = State.IDLE
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8) * 2.2

var _dash_timer: float = 0.0
var _dash_cooldown_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.FORWARD

var _attack_timer: float = 0.0
var _attack_is_dash_slice: bool = false
var _interact_timer: float = 0.0
var _facing_direction: Vector3 = Vector3.FORWARD
var _camera: HD2DCamera

func _ready() -> void:
	if not is_in_group("player"):
		add_to_group("player")
	
	# Recherche automatique du modèle 3D et de son AnimationPlayer
	if not model_root and has_node("Knight"):
		model_root = get_node("Knight")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	# Récupération de la caméra pour le feedback de shake
	var vp = get_viewport()
	if vp:
		var cam = vp.get_camera_3d()
		if cam is HD2DCamera:
			_camera = cam
	
	_setup_animation_loops()
	_change_state(State.IDLE)

## Configure le bouclage forcé (Animation.LOOP_LINEAR) sur les animations de locomotion
func _setup_animation_loops() -> void:
	if not anim_player:
		return
	var loop_animations = ["Idle", "Running_A", "Running_B", "Walking_A", "Walking_B", "Walking_C", "Jump_Idle"]
	for anim_name in loop_animations:
		if anim_player.has_animation(anim_name):
			var anim: Animation = anim_player.get_animation(anim_name)
			if anim:
				anim.loop_mode = Animation.LOOP_LINEAR

## Détection discrète et réactive des actions (Dash, Attaque, Saut, Interaction)
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		# Dash : Touche Shift
		if event.keycode == KEY_SHIFT or event.physical_keycode == KEY_SHIFT:
			_try_dash()
		# Attaque : Touche F ou J
		elif event.keycode in [KEY_F, KEY_J] or event.physical_keycode in [KEY_F, KEY_J]:
			_try_attack()
		# Saut : Touche Espace
		elif event.keycode == KEY_SPACE or event.physical_keycode == KEY_SPACE:
			_try_jump()
		# Interaction : Touche E
		elif event.keycode == KEY_E or event.physical_keycode == KEY_E:
			_try_interact()
	elif event is InputEventMouseButton and event.is_pressed():
		# Attaque : Clic gauche
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_attack()

func _physics_process(delta: float) -> void:
	# Décompte du cooldown de dash
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	# Application de la gravité sauf pendant le dash
	if not is_on_floor() and current_state != State.DASH:
		velocity.y -= gravity * delta

	# Support de l'action ui_accept pour le saut
	if Input.is_action_just_pressed("ui_accept"):
		_try_jump()

	# Exécution de l'état actif
	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.MOVE:
			_process_move(delta)
		State.JUMP:
			_process_jump(delta)
		State.DASH:
			_process_dash(delta)
		State.ATTACK:
			_process_attack(delta)
		State.INTERACT:
			_process_interact(delta)

	move_and_slide()

## =============================================================================
## LOGIQUE DES ÉTATS
## =============================================================================

func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.IDLE:
			_change_animation("Idle", 0.15)
		State.MOVE:
			_change_animation("Running_A", 0.15)
		State.JUMP:
			_change_animation("Jump_Start", 0.08)
		State.DASH:
			# Dodge_Forward joué à vitesse accélérée pour correspondre à la durée du dash
			_change_animation("Dodge_Forward", 0.04, 1.35)
		State.ATTACK:
			_attack_timer = 0.48
			# Coup d'épée vif et percutant
			_change_animation("1H_Melee_Attack_Slice_Horizontal", 0.05, 1.4)
			if _attack_is_dash_slice:
				velocity.x = _facing_direction.x * (move_speed * 1.5)
				velocity.z = _facing_direction.z * (move_speed * 1.5)
			else:
				velocity.x = _facing_direction.x * 2.2
				velocity.z = _facing_direction.z * 2.2
			
			if not _camera:
				var vp = get_viewport()
				if vp:
					var cam = vp.get_camera_3d()
					if cam is HD2DCamera:
						_camera = cam
			if _camera and _camera.has_method("add_trauma"):
				_camera.add_trauma(0.12)
		State.INTERACT:
			_interact_timer = 0.6
			_change_animation("Interact", 0.1)

func _process_idle(delta: float) -> void:
	# Décélération progressive par friction
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	var input_dir = _get_input_direction()
	if input_dir.length_squared() > 0.01:
		_change_state(State.MOVE)
	elif not is_on_floor():
		_change_state(State.JUMP)

func _process_move(delta: float) -> void:
	var input_dir = _get_input_direction()
	var is_moving = input_dir.length_squared() > 0.01

	if is_moving:
		var target_vel = Vector3(input_dir.x, 0.0, input_dir.y) * move_speed
		velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

		_facing_direction = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
		_rotate_model_towards(_facing_direction, delta)
		# Bouclage infini sécurisé : _change_animation ne réinitialise pas la frame en cours
		_change_animation("Running_A", 0.15)
	else:
		_change_state(State.IDLE)

	if not is_on_floor():
		_change_state(State.JUMP)

func _process_jump(delta: float) -> void:
	# Contrôle aérien
	var input_dir = _get_input_direction()
	if input_dir.length_squared() > 0.01:
		var target_vel = Vector3(input_dir.x, 0.0, input_dir.y) * (move_speed * 0.75)
		velocity.x = move_toward(velocity.x, target_vel.x, (acceleration * 0.5) * delta)
		velocity.z = move_toward(velocity.z, target_vel.z, (acceleration * 0.5) * delta)
		_rotate_model_towards(Vector3(input_dir.x, 0.0, input_dir.y), delta)

	if velocity.y < 0.0:
		_change_animation("Jump_Idle", 0.15)

	if is_on_floor():
		if input_dir.length_squared() > 0.01:
			_change_state(State.MOVE)
		else:
			_change_state(State.IDLE)

func _process_dash(delta: float) -> void:
	_dash_timer -= delta
	velocity.x = _dash_direction.x * dash_speed
	velocity.z = _dash_direction.z * dash_speed

	if _dash_timer <= 0.0:
		var input_dir = _get_input_direction()
		if input_dir.length_squared() > 0.01:
			_change_state(State.MOVE)
		else:
			_change_state(State.IDLE)

func _process_attack(delta: float) -> void:
	_attack_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	if _attack_timer <= 0.0:
		var input_dir = _get_input_direction()
		if input_dir.length_squared() > 0.01:
			_change_state(State.MOVE)
		else:
			_change_state(State.IDLE)

func _process_interact(delta: float) -> void:
	_interact_timer -= delta
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	velocity.z = move_toward(velocity.z, 0.0, friction * delta)

	if _interact_timer <= 0.0:
		_change_state(State.IDLE)

## =============================================================================
## DÉCLENCHEURS D'ACTIONS
## =============================================================================

func _try_dash() -> void:
	if _dash_cooldown_timer > 0.0 or current_state == State.DASH:
		return
	
	# Si en attaque, autoriser le Dodge-Cancel dès que le coup a porté (après 0.18s)
	if current_state == State.ATTACK and _attack_timer > 0.30:
		return
	
	var input_dir = _get_input_direction()
	if input_dir.length_squared() > 0.01:
		_dash_direction = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
	else:
		_dash_direction = _facing_direction
	
	_facing_direction = _dash_direction
	if model_root:
		model_root.rotation.y = atan2(_dash_direction.x, _dash_direction.z)
	
	_dash_timer = dash_duration
	_dash_cooldown_timer = dash_cooldown
	_change_state(State.DASH)

func _try_attack() -> void:
	# En attaque active, ignorer les doubles appuis trop précoces
	if current_state == State.ATTACK and _attack_timer > 0.20:
		return
	
	# Transition fluide : si on est en plein Dash, déclenche une attaque glissée (Dash-Attack)
	_attack_is_dash_slice = (current_state == State.DASH)
	
	var input_dir = _get_input_direction()
	if input_dir.length_squared() > 0.01:
		_facing_direction = Vector3(input_dir.x, 0.0, input_dir.y).normalized()
		if model_root:
			model_root.rotation.y = atan2(_facing_direction.x, _facing_direction.z)
	
	_change_state(State.ATTACK)

func _try_jump() -> void:
	if is_on_floor() and current_state != State.DASH and current_state != State.ATTACK:
		velocity.y = jump_velocity
		_change_state(State.JUMP)

func _try_interact() -> void:
	if current_state == State.DASH or current_state == State.ATTACK:
		return
	_change_state(State.INTERACT)

## Récupère le vecteur de déplacement ZQSD, WASD ou flèches
func _get_input_direction() -> Vector2:
	var dir = Vector2.ZERO

	# ZQSD (AZERTY) et WASD (QWERTY)
	if Input.is_physical_key_pressed(KEY_Z) or Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		dir.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_Q) or Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		dir.x += 1.0

	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	return dir.normalized()

func _rotate_model_towards(dir: Vector3, delta: float) -> void:
	if not model_root or dir.length_squared() < 0.01:
		return
	var target_rot_y = atan2(dir.x, dir.z)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rot_y, rotation_speed * delta)

## Sécurise le déclenchement des animations sans réinitialiser la frame en cours
func _change_animation(anim_name: String, blend_time: float = 0.15, speed: float = 1.0) -> void:
	if not anim_player or not anim_player.has_animation(anim_name):
		return
	if anim_player.current_animation == anim_name and anim_player.is_playing():
		return
	anim_player.play(anim_name, blend_time, speed)
