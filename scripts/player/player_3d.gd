class_name Player3D
extends CharacterBody3D

## Contrôleur Joueur 3D Stylisé (Modèle Rigged KayKit avec AnimationPlayer)
## Locomotion fluide avec rotation.y lerp_angle, coup d'épée 3D avec Hitbox, bruitages et SFX.

signal stats_changed(hp: int, max_hp: int, mana: int, max_mana: int, gold: int)
signal player_attacked()

@export var move_speed: float = 6.0
@export var acceleration: float = 30.0
@export var friction: float = 24.0
@export var rotation_speed: float = 12.0

@export var max_hp: int = 5
@export var max_mana: int = 100
var hp: int = 5
var mana: int = 100
var gold: int = 0
var enemies_killed: int = 0

var is_attacking: bool = false
var _attack_timer: float = 0.0
var _footstep_timer: float = 0.0
var current_interactable: Node = null

@onready var model_root: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/Knight/AnimationPlayer
@onready var sfx_sword: AudioStreamPlayer3D = $SFXSword
@onready var sfx_step: AudioStreamPlayer3D = $SFXStep
@onready var attack_area: Area3D = $AttackArea

func set_current_interactable(interactable: Node) -> void:
	current_interactable = interactable

func clear_current_interactable(interactable: Node) -> void:
	if current_interactable == interactable:
		current_interactable = null

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E)) and current_interactable:
		if current_interactable.has_method("trigger_interaction"):
			current_interactable.trigger_interaction(self)

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	mana = max_mana
	
	# Configuration du bouclage des animations
	if anim_player:
		for loop_anim in ["Idle", "Running_A", "Walking_A"]:
			if anim_player.has_animation(loop_anim):
				anim_player.get_animation(loop_anim).loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")
		anim_player.animation_finished.connect(_on_animation_finished)

	stats_changed.emit(hp, max_hp, mana, max_mana, gold)

func _physics_process(delta: float) -> void:
	# Gravité
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	# Entrée Attaque (Clic Gauche ou Espace)
	if (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE)) and not is_attacking:
		_perform_attack()

	# Entrées de déplacement ZQSD / WASD / Flèches
	var input_x: float = 0.0
	var input_z: float = 0.0

	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
		input_x += 1.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
		input_z += 1.0
	if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
		input_z -= 1.0

	var move_dir: Vector3 = Vector3(input_x, 0.0, input_z).normalized()

	if not is_attacking:
		if move_dir.length_squared() > 0.01:
			var target_vel = move_dir * move_speed
			velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)

			# Rotation fluide vers la direction de course
			var target_angle = atan2(move_dir.x, move_dir.z)
			if model_root:
				model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, rotation_speed * delta)

			# Joue l'animation de course
			if anim_player and anim_player.current_animation != "Running_A":
				anim_player.play("Running_A")

			# Son de pas régulier
			_footstep_timer += delta
			if _footstep_timer >= 0.35:
				_footstep_timer = 0.0
				if sfx_step and not sfx_step.playing:
					sfx_step.pitch_scale = randf_range(0.9, 1.1)
					sfx_step.play()
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
			if anim_player and anim_player.current_animation != "Idle":
				anim_player.play("Idle")
			_footstep_timer = 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 1.5 * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * 1.5 * delta)

	move_and_slide()

func _perform_attack() -> void:
	is_attacking = true
	player_attacked.emit()
	
	# Choix de l'animation d'attaque épée
	if anim_player:
		var attack_anims = ["1H_Melee_Attack_Slice_Horizontal", "1H_Melee_Attack_Chop"]
		var chosen = attack_anims[randi() % attack_anims.size()]
		if anim_player.has_animation(chosen):
			anim_player.play(chosen)
		elif anim_player.has_animation("1H_Melee_Attack_Slice_Horizontal"):
			anim_player.play("1H_Melee_Attack_Slice_Horizontal")

	# Bruitage d'attaque
	if sfx_sword:
		sfx_sword.pitch_scale = randf_range(0.95, 1.1)
		sfx_sword.play()

	# Détection de collision de frappe
	if attack_area:
		var forward = -model_root.global_transform.basis.z if model_root else -global_transform.basis.z
		for body in attack_area.get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("take_hit"):
				var knockback = (body.global_position - global_position).normalized()
				body.take_hit(1, knockback)
			elif body.is_in_group("destructible") and body.has_method("take_hit"):
				body.take_hit(self)
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("destructible"):
				var parent_barrel = area.get_parent()
				if parent_barrel and parent_barrel.has_method("take_hit"):
					parent_barrel.take_hit(self)

func take_hit(damage: int) -> void:
	if hp <= 0:
		return
	hp = max(0, hp - damage)
	stats_changed.emit(hp, max_hp, mana, max_mana, gold)
	if anim_player and anim_player.has_animation("Hit_A") and hp > 0:
		anim_player.play("Hit_A")
	elif hp <= 0 and anim_player and anim_player.has_animation("Death_A"):
		anim_player.play("Death_A")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("1H_Melee_Attack"):
		is_attacking = false
		if anim_player:
			anim_player.play("Idle")

func add_gold(amount: int) -> void:
	gold += amount
	stats_changed.emit(hp, max_hp, mana, max_mana, gold)

func record_kill() -> void:
	enemies_killed += 1
	add_gold(15)
