class_name DestructibleBarrel
extends Node3D

const LootItemScript = preload("res://scripts/props/loot_item.gd")

## Tonneau ou pile de tonneaux destructible à l'épée
## - Encaisse les coups via Area3D (groupe "destructible")
## - Bloque le passage du joueur avant destruction
## - Déclenche secousse caméra (trauma 0.22) + hitstop (0.04s)
## - Émet des débris de bois (CPUParticles3D) et masque son maillage
## - Fait émerger une pièce d'or ou une potion avec pop et ramassage

enum BarrelLootType {
	COIN,
	POTION,
	RANDOM
}

@export var max_health: int = 1
@export var loot_type: BarrelLootType = BarrelLootType.COIN

var current_health: int = 1
var is_destroyed: bool = false
var _solid_body: StaticBody3D = null
var _hurtbox: Area3D = null

func _ready() -> void:
	add_to_group("destructible")
	current_health = max_health
	_setup_collision()

func _setup_collision() -> void:
	# 1. StaticBody3D pour empêcher le joueur de traverser le tonneau avant sa destruction
	_solid_body = find_child("SolidCollider", true, false) as StaticBody3D
	if not _solid_body:
		_solid_body = StaticBody3D.new()
		_solid_body.name = "SolidCollider"
		var col = CollisionShape3D.new()
		col.name = "SolidShape"
		var shape = CylinderShape3D.new()
		shape.radius = 0.65
		shape.height = 1.4
		col.shape = shape
		col.position = Vector3(0, 0.7, 0)
		_solid_body.add_child(col)
		add_child(_solid_body)

	# 2. Area3D Hurtbox pour recevoir les attaques
	_hurtbox = find_child("Hurtbox", true, false) as Area3D
	if not _hurtbox:
		_hurtbox = Area3D.new()
		_hurtbox.name = "Hurtbox"
		_hurtbox.add_to_group("destructible")
		_hurtbox.collision_layer = 1
		_hurtbox.collision_mask = 0
		var col = CollisionShape3D.new()
		col.name = "HurtboxShape"
		var shape = CylinderShape3D.new()
		shape.radius = 0.85
		shape.height = 1.8
		col.shape = shape
		col.position = Vector3(0, 0.9, 0)
		_hurtbox.add_child(col)
		add_child(_hurtbox)
	else:
		if not _hurtbox.is_in_group("destructible"):
			_hurtbox.add_to_group("destructible")

func take_hit(attacker: Node = null) -> void:
	if is_destroyed:
		return
	
	current_health -= 1
	if current_health <= 0:
		destroy(attacker)

func destroy(attacker: Node = null) -> void:
	if is_destroyed:
		return
	is_destroyed = true
	
	# 1. Screen Shake sur la caméra HD-2D
	var cam: HD2DCamera = null
	if attacker and "_camera" in attacker and attacker._camera:
		cam = attacker._camera
	if not cam:
		var vp = get_viewport()
		if vp:
			var c = vp.get_camera_3d()
			if c is HD2DCamera:
				cam = c
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.22)
	
	# 2. Hitstop micro-pause d'impact (~0.04s)
	_apply_hitstop(0.04)
	
	# 3. Masquer tous les maillages du tonneau
	for child in find_children("*", "MeshInstance3D", true, false):
		if child is MeshInstance3D:
			child.visible = false
	
	# 4. Désactiver les collisions physiques
	if _solid_body:
		for col in _solid_body.find_children("*", "CollisionShape3D", true, false):
			col.set_deferred("disabled", true)
	if _hurtbox:
		for col in _hurtbox.find_children("*", "CollisionShape3D", true, false):
			col.set_deferred("disabled", true)
	
	# 5. Effet de débris et poussière de bois
	_spawn_wood_debris()
	
	# 6. Émergence du butin (Loot)
	_spawn_loot()

func _apply_hitstop(duration: float = 0.04) -> void:
	Engine.time_scale = 0.05
	var timer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func():
		Engine.time_scale = 1.0
	)

func _spawn_wood_debris() -> void:
	var particles = CPUParticles3D.new()
	particles.name = "WoodDebris"
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 18
	particles.lifetime = 0.65
	
	# Éclats de bois cubiques
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.18)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.33, 0.15)
	mat.roughness = 0.9
	box.material = mat
	particles.mesh = box
	
	# Éjection en cône vers le haut
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 70.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.position = Vector3(0, 0.6, 0)
	add_child(particles)

func _spawn_loot() -> void:
	var loot = LootItemScript.new()
	if loot_type == BarrelLootType.COIN:
		loot.loot_type = 0 # LootType.COIN
	elif loot_type == BarrelLootType.POTION:
		loot.loot_type = 1 # LootType.POTION
	else:
		loot.loot_type = 0 if randf() > 0.4 else 1
	
	loot.global_position = global_position + Vector3(0, 0.2, 0)
	get_parent().add_child(loot)
