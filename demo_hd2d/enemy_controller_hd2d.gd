extends CharacterBody3D

## Contrôleur Ennemi 3D HD-2D (Garde Corrompu / Squelette)
## Utilise AnimatedSprite3D, gère la patrouille/poursuite, le recul à l'impact et le flash de dégâts.

@export var move_speed: float = 2.4
@export var detection_range: float = 8.0
@export var attack_range: float = 1.6
@export var max_hp: int = 3

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

var hp: int = 3
var is_hurt: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var _hurt_timer: float = 0.0
var _attack_cooldown: float = 0.0

var player: Node3D = null

func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("idle")
	
	# Recherche du joueur
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Gravité
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	# Gestion du timer de recul / blessure
	if is_hurt:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			is_hurt = false
			if sprite:
				sprite.modulate = Color.WHITE

	# Cooldown d'attaque
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta

	# Recherche dynamique du joueur si non trouvé
	if not player:
		player = get_tree().get_first_node_in_group("player")

	# IA de déplacement si pas blessé ni en train d'attaquer
	if not is_hurt and not is_attacking and player:
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		var dist: float = to_player.length()

		if dist <= attack_range and _attack_cooldown <= 0.0:
			_start_attack(to_player)
		elif dist <= detection_range and dist > attack_range * 0.9:
			var dir: Vector3 = to_player.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed

			# Orientation : STRICTEMENT flip_h (interdiction de scale.x)
			if sprite:
				if dir.x < -0.05:
					sprite.flip_h = true
				elif dir.x > 0.05:
					sprite.flip_h = false

			if sprite and sprite.animation != "walk":
				sprite.play("walk")
		else:
			# À l'arrêt
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if sprite and sprite.animation != "idle":
				sprite.play("idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	move_and_slide()

func _start_attack(to_player: Vector3) -> void:
	is_attacking = true
	_attack_cooldown = 1.8
	if sprite:
		if to_player.x < 0:
			sprite.flip_h = true
		else:
			sprite.flip_h = false
		sprite.play("attack")

func _on_animation_finished() -> void:
	if sprite and sprite.animation == "attack":
		is_attacking = false
		sprite.play("idle")

func take_hit(damage: int, knockback_dir: Vector3) -> void:
	if is_dead:
		return

	hp -= damage
	is_hurt = true
	_hurt_timer = 0.25
	is_attacking = false

	# Effet de recul physique
	velocity.x = knockback_dir.x * 5.5
	velocity.z = knockback_dir.z * 5.5
	velocity.y = 2.0

	# Flash blanc/rouge de hit
	if sprite:
		sprite.modulate = Color(2.5, 0.4, 0.4, 1.0)

	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	velocity = Vector3.ZERO
	# Disparition progressive par tween
	var tween = create_tween()
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
