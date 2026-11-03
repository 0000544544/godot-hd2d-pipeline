class_name EnemySkeleton
extends CharacterBody3D

## Ennemi Squelette Modulaire (KayKit Low-Poly 3D)
## Gère 4 archétypes :
## - WARRIOR : Guerrier équilibré à l'épée
## - ROGUE : Rôdeur véloce à doubles lames
## - MAGE : Sorcier de l'ombre attaquant à distance avec orbes magiques
## - MINION : Sbire agile des ruines
##
## Animations KayKit intégrées (Idle, Walk, Run, Attacks, Hit, Death_A sans basculement)

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	HIT,
	DEATH
}

enum SkeletonType {
	WARRIOR,
	ROGUE,
	MAGE,
	MINION
}

signal defeated(skeleton: Node)

const LootItemScript = preload("res://scripts/props/loot_item.gd")

@export var skeleton_type: SkeletonType = SkeletonType.WARRIOR
@export var max_health: int = 3
@export var patrol_distance: float = 3.5
@export var walk_speed: float = 1.8
@export var chase_speed: float = 3.2
@export var detection_range: float = 6.5
@export var attack_range: float = 1.8

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
var _attack_has_dealt_damage: bool = false

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("destructible") # Permet au joueur de le frapper directement
	
	_origin_pos = global_position
	_configure_type_parameters()
	current_health = max_health
	
	_resolve_model_and_anim()
	
	if not player_target:
		player_target = get_tree().get_first_node_in_group("player")
		if not player_target:
			var p = get_parent()
			if p:
				player_target = p.find_child("Player", true, false)
	
	_setup_hurtbox()
	_change_state(State.PATROL)

func _configure_type_parameters() -> void:
	match skeleton_type:
		SkeletonType.WARRIOR:
			max_health = 3
			walk_speed = 1.8
			chase_speed = 3.2
			attack_range = 1.8
			detection_range = 6.5
		SkeletonType.ROGUE:
			max_health = 2
			walk_speed = 2.4
			chase_speed = 4.2
			attack_range = 1.7
			detection_range = 7.5
		SkeletonType.MAGE:
			max_health = 3
			walk_speed = 1.5
			chase_speed = 2.4
			attack_range = 6.5
			detection_range = 9.0
		SkeletonType.MINION:
			max_health = 2
			walk_speed = 2.2
			chase_speed = 3.8
			attack_range = 1.6
			detection_range = 6.0

func _resolve_model_and_anim() -> void:
	if not model_root:
		for candidate in ["Skeleton_Warrior", "Skeleton_Rogue", "Skeleton_Mage", "Skeleton_Minion"]:
			if has_node(candidate):
				model_root = get_node(candidate)
				break
		if not model_root:
			for c in get_children():
				if c.name.begins_with("Skeleton"):
					model_root = c
					break

	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
		if not anim_player:
			for c in model_root.get_children():
				if c is AnimationPlayer:
					anim_player = c
					break

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
	
	if not is_instance_valid(player_target):
		player_target = get_tree().get_first_node_in_group("player")
	
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
			
			# Exécution de l'impact à mi-animation
			_process_attack_impact(dist_to_player)
			
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
			_state_timer = randf_range(0.8, 1.8)
			_play_anim("Idle")
		State.PATROL:
			_play_anim("Walking_A")
		State.CHASE:
			_play_anim("Running_A")
		State.ATTACK:
			_attack_has_dealt_damage = false
			_orient_towards_player()
			if skeleton_type == SkeletonType.MAGE:
				_state_timer = 1.1
				_play_anim("Spellcast_Shoot")
			elif skeleton_type == SkeletonType.ROGUE:
				_state_timer = 0.75
				if anim_player and anim_player.has_animation("Dualwield_Melee_Attack_Slice"):
					_play_anim("Dualwield_Melee_Attack_Slice")
				else:
					_play_anim("1H_Melee_Attack_Slice_Diagonal")
			else:
				_state_timer = 0.85
				_play_anim("1H_Melee_Attack_Slice_Horizontal")
		State.HIT:
			_state_timer = 0.42
			_play_anim("Hit_A")
		State.DEATH:
			is_dead = true
			velocity = Vector3.ZERO
			defeated.emit(self)
			_play_anim("Death_A")
			_on_defeated()

func _orient_towards_player() -> void:
	if is_instance_valid(player_target) and model_root:
		var dir = (player_target.global_position - global_position)
		dir.y = 0
		if dir.length_squared() > 0.001:
			model_root.rotation.y = atan2(dir.x, dir.z)

func _process_attack_impact(dist_to_player: float) -> void:
	if _attack_has_dealt_damage:
		return
	
	if skeleton_type == SkeletonType.MAGE:
		# Déclenchement du projectile à 0.45s du sortilège
		if _state_timer <= 0.65:
			_attack_has_dealt_damage = true
			_cast_magic_projectile()
	else:
		# Attaque de mêlée percutante à 0.4s
		if _state_timer <= 0.45:
			_attack_has_dealt_damage = true
			if dist_to_player <= attack_range + 0.6 and is_instance_valid(player_target):
				if player_target.has_method("take_damage"):
					player_target.take_damage(1)

func _cast_magic_projectile() -> void:
	var target_pos = player_target.global_position + Vector3(0, 0.8, 0) if is_instance_valid(player_target) else global_position + Vector3(0, 0.8, 2)
	var spawn_pos = global_position + Vector3(0, 1.2, 0)
	var dir = (target_pos - spawn_pos).normalized()
	
	var orb = Node3D.new()
	orb.name = "MageOrb"
	
	# Mesh orbe mystique
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.8, 0.4, 2.2, 1.0)
	mesh_inst.mesh = sphere
	mesh_inst.material_override = mat
	orb.add_child(mesh_inst)
	
	# Halo lumineux
	var light = OmniLight3D.new()
	light.light_color = Color(0.85, 0.3, 1.0)
	light.light_energy = 2.5
	light.omni_range = 3.5
	orb.add_child(light)
	
	var parent_scene = get_parent()
	if not parent_scene:
		parent_scene = get_tree().current_scene
	parent_scene.add_child(orb)
	orb.global_position = spawn_pos
	
	# Trajectoire balistique fluide via un script dynamique
	var timer = 0.0
	var speed = 7.5
	var process_lambda = func(delta: float):
		if not is_instance_valid(orb):
			return
		timer += delta
		orb.global_position += dir * speed * delta
		
		# Collision avec le joueur
		var players = orb.get_tree().get_nodes_in_group("player")
		for p in players:
			if is_instance_valid(p) and orb.global_position.distance_to(p.global_position + Vector3(0, 0.8, 0)) <= 0.85:
				if p.has_method("take_damage"):
					p.take_damage(1)
				_spawn_magic_burst(orb.global_position)
				orb.queue_free()
				return
		
		if timer >= 2.5:
			orb.queue_free()
	
	# Attacher la fonction au frame process
	var tree = get_tree()
	if tree:
		var conn: Callable
		conn = func():
			var dt = tree.root.get_process_delta_time()
			process_lambda.call(dt)
			if not is_instance_valid(orb):
				if tree.process_frame.is_connected(conn):
					tree.process_frame.disconnect(conn)
		tree.process_frame.connect(conn)

func _spawn_magic_burst(pos: Vector3) -> void:
	var p = CPUParticles3D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 16
	p.lifetime = 0.4
	
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.06, 0.06)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(2.0, 0.5, 2.5)
	p.mesh = box
	p.material_override = mat
	p.direction = Vector3(0, 1, 0)
	p.spread = 80.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.0
	
	var parent_scene = get_parent()
	if parent_scene:
		parent_scene.add_child(p)
		p.global_position = pos
		get_tree().create_timer(0.6).timeout.connect(func(): p.queue_free())

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

## Réception d'une frappe du joueur
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
		velocity += knockback_dir.normalized() * 3.8
	
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
	p.amount = 14
	p.lifetime = 0.4
	
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 0.08)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.9, 0.82)
	p.mesh = box
	p.material_override = mat
	p.direction = Vector3(0, 1, 0)
	p.spread = 60.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 3.5
	p.position = Vector3(0, 0.9, 0)
	add_child(p)
	get_tree().create_timer(0.5).timeout.connect(func(): p.queue_free())

func _on_defeated() -> void:
	# Désactiver les collisions
	var col = find_child("CollisionShape3D", true, false) as CollisionShape3D
	if col:
		col.set_deferred("disabled", true)
	if _hurtbox:
		for c in _hurtbox.find_children("*", "CollisionShape3D", true, false):
			c.set_deferred("disabled", true)
	
	# Butin : 1 à 2 objets avec rebond et dispersion
	_spawn_loot()
	
	# Le squelette reste étendu sur le sol dans sa pose de mort (Death_A) puis disparaît doucement
	var timer = get_tree().create_timer(4.0)
	timer.timeout.connect(func():
		if is_instance_valid(self):
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
			tween.tween_callback(func(): queue_free())
	)

func _spawn_loot() -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	var count = randi_range(1, 2)
	for i in range(count):
		var loot = LootItemScript.new()
		# 70% Pièce d'or (+10 Or), 30% Potion de soin (+2 PV)
		loot.loot_type = LootItem.LootType.COIN if randf() > 0.30 else LootItem.LootType.POTION
		
		# Dispersion horizontale aléatoire
		var scatter = Vector3(randf_range(-0.65, 0.65), 0.0, randf_range(-0.65, 0.65))
		parent_node.add_child(loot)
		loot.global_position = global_position + Vector3(0, 0.2, 0)
		loot._play_spawn_pop_animation(scatter)
