class_name EnemySkeleton3D
extends CharacterBody3D

## Contrôleur Ennemi 3D Squelette (Modèle KayKit Skeleton_Warrior avec AnimationPlayer)
## Machine à états IA (Patrouille / Poursuite / Attaque), animations Hit/Death, recul physique et audio.

@export var move_speed: float = 2.6
@export var detection_range: float = 9.0
@export var attack_range: float = 1.6
@export var max_hp: int = 3

var hp: int = 3
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var _attack_cooldown: float = 0.0

@onready var model_root: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/Skeleton_Warrior/AnimationPlayer
@onready var sfx_hit: AudioStreamPlayer3D = $SFXHit
@onready var label_damage: Label3D = $DamageLabel

var player: Node3D = null

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	
	if anim_player:
		for loop_anim in ["Idle", "Walking_A", "Running_A"]:
			if anim_player.has_animation(loop_anim):
				anim_player.get_animation(loop_anim).loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")
		anim_player.animation_finished.connect(_on_animation_finished)

	player = get_tree().get_first_node_in_group("player")
	if label_damage:
		label_damage.visible = false

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravité
	if not is_on_floor():
		velocity.y -= 19.6 * delta
	else:
		velocity.y = 0.0

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	if not player:
		player = get_tree().get_first_node_in_group("player")

	# IA de déplacement & combat
	if not is_hurt and not is_attacking and player:
		var to_player = player.global_position - global_position
		to_player.y = 0.0
		var dist = to_player.length()

		if dist <= attack_range and _attack_cooldown <= 0.0:
			_perform_enemy_attack(to_player)
		elif dist <= detection_range and dist > attack_range * 0.9:
			var dir = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

			# Orientation vers le joueur
			var target_angle = atan2(dir.x, dir.z)
			if model_root:
				model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, 8.0 * delta)

			if anim_player and anim_player.current_animation != "Walking_A":
				anim_player.play("Walking_A")
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if anim_player and anim_player.current_animation != "Idle":
				anim_player.play("Idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	move_and_slide()

func _perform_enemy_attack(to_player: Vector3) -> void:
	is_attacking = true
	_attack_cooldown = 2.0
	
	var dir = to_player.normalized()
	if model_root:
		model_root.rotation.y = atan2(dir.x, dir.z)
		
	if anim_player:
		if anim_player.has_animation("1H_Melee_Attack_Slice_Horizontal"):
			anim_player.play("1H_Melee_Attack_Slice_Horizontal")
		elif anim_player.has_animation("1H_Melee_Attack_Chop"):
			anim_player.play("1H_Melee_Attack_Chop")

	# Infliger des dégâts au joueur au sommet de l'attaque
	get_tree().create_timer(0.35).timeout.connect(func():
		if is_instance_valid(self) and not is_dead and player and is_instance_valid(player):
			var dist = (player.global_position - global_position).length()
			if dist <= attack_range * 1.3 and player.has_method("take_hit"):
				player.take_hit(1)
	)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name.begins_with("1H_Melee_Attack"):
		is_attacking = false
		if anim_player and not is_dead:
			anim_player.play("Idle")
	elif anim_name == "Hit_A":
		is_hurt = false
		if anim_player and not is_dead:
			anim_player.play("Idle")
	elif anim_name.begins_with("Death"):
		queue_free()

func take_hit(damage: int, knockback_dir: Vector3) -> void:
	if is_dead:
		return

	hp -= damage
	is_hurt = true
	is_attacking = false

	# Bruitage d'impact
	if sfx_hit:
		sfx_hit.pitch_scale = randf_range(0.9, 1.15)
		sfx_hit.play()

	# Recul physique
	velocity.x = knockback_dir.x * 6.0
	velocity.z = knockback_dir.z * 6.0
	velocity.y = 2.5

	# Animation d'impact
	if anim_player and anim_player.has_animation("Hit_A") and hp > 0:
		anim_player.play("Hit_A")

	# Pop-up de dégâts 3D
	_show_damage_popup(damage)

	if hp <= 0:
		_die()

func _show_damage_popup(amount: int) -> void:
	if not label_damage:
		return
	label_damage.text = "-%d" % amount
	label_damage.visible = true
	label_damage.position.y = 1.8
	var tween = create_tween()
	tween.tween_property(label_damage, "position:y", 2.4, 0.45)
	tween.parallel().tween_property(label_damage, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func():
		label_damage.visible = false
		label_damage.modulate.a = 1.0
	)

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

	# Avertir le joueur pour l'or et le compteur
	var p = get_tree().get_first_node_in_group("player")
	if p and p.has_method("record_kill"):
		p.record_kill()

	if anim_player:
		var death_anims = ["Death_A", "Death_B"]
		var chosen = death_anims[randi() % death_anims.size()]
		if anim_player.has_animation(chosen):
			anim_player.play(chosen)
		else:
			queue_free()
	else:
		queue_free()
