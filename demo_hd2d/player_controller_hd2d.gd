extends CharacterBody3D

## Contrôleur Joueur 3D HD-2D (Style Octopath Traveler)
## Gère le mouvement sur le plan X/Z, l'orientation via flip_h stricte et les animations AnimatedSprite3D.

@export var move_speed: float = 5.5
@export var acceleration: float = 32.0
@export var friction: float = 24.0

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

var is_attacking: bool = false
var facing_left: bool = false

func _ready() -> void:
	add_to_group("player")
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	# 1. Gestion de la gravité
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	# 2. Entrées d'attaque (Espace ou Clic Gauche)
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE):
		if not is_attacking:
			_start_attack()

	# 3. Calcul de la direction de déplacement (Support ZQSD, WASD et Flèches)
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

	# 4. Orientation : STRICTEMENT avec animated_sprite.flip_h (jamais de modification de scale.x)
	if move_dir.x < -0.05:
		facing_left = true
		if sprite:
			sprite.flip_h = true
	elif move_dir.x > 0.05:
		facing_left = false
		if sprite:
			sprite.flip_h = false

	# 5. Application de la vitesse avec inertie et friction
	if not is_attacking:
		if move_dir.length_squared() > 0.01:
			var target_vel = move_dir * move_speed
			velocity.x = move_toward(velocity.x, target_vel.x, acceleration * delta)
			velocity.z = move_toward(velocity.z, target_vel.z, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
			velocity.z = move_toward(velocity.z, 0.0, friction * delta)
	else:
		# Ralentissement pendant le coup d'épée
		velocity.x = move_toward(velocity.x, 0.0, friction * 1.5 * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * 1.5 * delta)

	move_and_slide()

	# 6. Mise à jour de l'animation
	_update_animation()

func _update_animation() -> void:
	if not sprite:
		return

	if is_attacking:
		if sprite.animation != "attack":
			sprite.play("attack")
		return

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")

func _start_attack() -> void:
	is_attacking = true
	if sprite:
		sprite.play("attack")

	# Détection de collision d'attaque au corps à corps
	var attack_range: float = 2.4
	var hit_angle: float = 1.2
	var forward_dir: Vector3 = Vector3.LEFT if facing_left else Vector3.RIGHT

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is CharacterBody3D and enemy.has_method("take_hit"):
			var to_enemy: Vector3 = enemy.global_position - global_position
			to_enemy.y = 0.0
			var dist: float = to_enemy.length()
			if dist <= attack_range:
				var knockback_dir: Vector3 = to_enemy.normalized()
				if knockback_dir.length_squared() < 0.1:
					knockback_dir = forward_dir
				enemy.take_hit(1, knockback_dir)

func _on_animation_finished() -> void:
	if sprite and sprite.animation == "attack":
		is_attacking = false
		_update_animation()
