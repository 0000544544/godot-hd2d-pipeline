class_name EnemySkeleton
extends CharacterBody3D

## Ennemi Squelette Guerrier (KayKit Low-Poly 3D)
## - Compatible avec le pipeline HD-2D et les attaques du joueur
## - Détection de portée, poursuite et attaque à l'épée
## - Encaisse les coups du joueur via take_hit() avec animation de recul et hitstop
## - S'effondre à la mort (Death_A) et fait émerger un butin (pièce / potion)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT,
	DEATH
}

const LootItemScript = preload("res://scripts/props/loot_item.gd")

@export var max_health: int = 3
@export var patrol_distance: float = 3.5
@export var walk_speed: float = 1.8
@export var chase_speed: float = 3.2
@export var detection_range: float = 6.5
@export var attack_range: float = 1.5

@export var model_root: Node3D
@export var anim_player: AnimationPlayer
@export var player_target: Node3D

var current_state: State = State.IDLE
var current_health: int = 3
var is_dead: bool = false

var _origin_pos: Vector3
var _patrol_dir: float = 1.0
var _state_timer: float = 0.0
var _hurtbox: Area3D = null

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("destructible") # Permet au système d'attaque du joueur de le cibler directement
	
	current_health = max_health
	_origin_pos = global_position
	
	if not model_root and has_node("Skeleton_Warrior"):
		model_root = get_node("Skeleton_Warrior")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	if not player_target:
		player_target = get_tree().get_first_node_in_group("player")
		if not player_target:
			player_target = get_parent().find_child("Player", true, false)
	
	_setup_hurtbox()
	_change_state(State.PATROL)

func _setup_hurtbox() -> void:
	_hurtbox = find_child("Hurtbox", true, false) as Area3D
	if not _hurtbox:
		_hurtbox = Area3D.new()
		_hurtbox.name = "Hurtbox"
		_hurtbox.add_to_group("destructible")
		_hurtbox.collision_layer = 1
		_hurtbox.collision_mask = 0
		var col = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.45
		shape.height = 1.7
		col.shape = shape
		col.position = Vector3(0, 0.85, 0)
		_hurtbox.add_child(col)
		add_child(_hurtbox)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Gravité
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	
	if not player_target:
		player_target = get_tree().get_first_node_in_group("player")
		if not player_target:
			var p = get_parent()
			if p:
				player_target = p.find_child("Player", true, false)
	
	var dist_to_player := INF
	if is_instance_valid(player_target):
		dist_to_player = global_position.distance_to(player_target.global_position)
	
	match current_state:
		State.IDLE:
			velocity.x = move_toward(velocity.x, 0, walk_speed * delta * 5)
			velocity.z = move_toward(velocity.z, 0, walk_speed * delta * 5)
			_state_timer -= delta
			if dist_to_player <= detection_range:
				_change_state(State.CHASE)
			elif _state_timer <= 0:
				_change_state(State.PATROL)
				
		State.PATROL:
			if dist_to_player <= detection_range:
				_change_state(State.CHASE)
			else:
				var offset = global_position.x - _origin_pos.x
				if abs(offset) > patrol_distance:
					_patrol_dir = -sign(offset)
				
				var move_dir = Vector3(_patrol_dir, 0, 0).normalized()
				velocity.x = move_dir.x * walk_speed
				velocity.z = 0.0
				_rotate_model(move_dir, delta)
				
		State.CHASE:
			if dist_to_player <= attack_range:
				_change_state(State.ATTACK)
			elif dist_to_player > detection_range * 1.5:
				_change_state(State.PATROL)
			elif is_instance_valid(player_target):
				var dir = (player_target.global_position - global_position)
				dir.y = 0
				dir = dir.normalized()
				velocity.x = dir.x * chase_speed
				velocity.z = dir.z * chase_speed
				_rotate_model(dir, delta)
				
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0, walk_speed * delta * 6)
			velocity.z = move_toward(velocity.z, 0, walk_speed * delta * 6)
			_state_timer -= delta
			if _state_timer <= 0:
				_change_state(State.IDLE)
				
		State.HIT:
			velocity.x = move_toward(velocity.x, 0, walk_speed * delta * 4)
			velocity.z = move_toward(velocity.z, 0, walk_speed * delta * 4)
			_state_timer -= delta
			if _state_timer <= 0:
				_change_state(State.CHASE if dist_to_player <= detection_range else State.PATROL)
	
	move_and_slide()

func _rotate_model(dir: Vector3, delta: float) -> void:
	if not model_root or dir.length_squared() < 0.001:
		return
	var target_angle = atan2(dir.x, dir.z)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_angle, 10.0 * delta)

func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.IDLE:
			_state_timer = randf_range(1.0, 2.5)
			_play_anim("Idle")
		State.PATROL:
			_play_anim("Walking_A")
		State.CHASE:
			_play_anim("Running_A")
		State.ATTACK:
			_state_timer = 0.8
			_play_anim("1H_Melee_Attack_Slice_Horizontal")
			if is_instance_valid(player_target):
				var dir = (player_target.global_position - global_position)
				dir.y = 0
				if dir.length_squared() > 0.001:
					model_root.rotation.y = atan2(dir.x, dir.z)
		State.HIT:
			_state_timer = 0.45
			_play_anim("Hit_A")
		State.DEATH:
			is_dead = true
			velocity = Vector3.ZERO
			_play_anim("Death_A")
			_on_defeated()

func _play_anim(anim_name: String) -> void:
	if not anim_player:
		return
	if anim_player.has_animation(anim_name):
		var anim = anim_player.get_animation(anim_name)
		if anim and anim_name in ["Idle", "Walking_A", "Running_A"]:
			anim.loop_mode = Animation.LOOP_LINEAR
		elif anim:
			anim.loop_mode = Animation.LOOP_NONE
		anim_player.play(anim_name)

## Méthode universelle de réception des attaques
func take_hit(attacker: Node = null) -> void:
	if is_dead:
		return
	
	current_health -= 1
	
	# Caméra Shake
	var vp = get_viewport()
	if vp:
		var cam = vp.get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.18)
	
	# Recul (Knockback)
	if attacker and is_instance_valid(attacker):
		var knockback_dir = (global_position - attacker.global_position)
		knockback_dir.y = 0.2
		velocity += knockback_dir.normalized() * 3.5
	
	# Effet de particules d'impact (poussière d'os)
	_spawn_hit_particles()
	
	if current_health <= 0:
		_change_state(State.DEATH)
	else:
		_change_state(State.HIT)

func _spawn_hit_particles() -> void:
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 12
	p.lifetime = 0.4
	
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.88, 0.8)
	box.material = mat
	p.mesh = box
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 3.5
	p.position = Vector3(0, 0.9, 0)
	add_child(p)

func _on_defeated() -> void:
	# Désactiver les collisions
	var col = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.set_deferred("disabled", true)
	if _hurtbox:
		for c in _hurtbox.find_children("*", "CollisionShape3D", true, false):
			c.set_deferred("disabled", true)
	
	_spawn_loot()

func _spawn_loot() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	var loot = LootItemScript.new()
	loot.loot_type = 0 if randf() > 0.4 else 1 # Pièce d'or ou potion
	parent_node.add_child(loot)
	loot.global_position = global_position + Vector3(0, 0.2, 0)
