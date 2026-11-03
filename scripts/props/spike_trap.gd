class_name SpikeTrap
extends Node3D

## Piège à pointes de sol (Inspiré de Crypt of the Sovereign)
## - Détecte le passage du joueur ou des ennemis
## - Déclenchement avec micro-délai mécanique
## - Éjection brutale de pointes métalliques + secousse caméra (trauma) + étincelles
## - Inflige des dégâts / recul à toute entité sur la dalle
## - Rétraction automatique après temporisation

@export var damage: int = 1
@export var trigger_delay: float = 0.25
@export var active_duration: float = 0.8
@export var reset_cooldown: float = 1.4

var is_active: bool = false
var is_cooling_down: bool = false

var _base_plate: MeshInstance3D
var _spikes_root: Node3D
var _trigger_area: Area3D
var _sparks: CPUParticles3D

func _ready() -> void:
	_build_visuals()
	_setup_trigger_area()

func _build_visuals() -> void:
	# 1. Dalle de sol en fer forgé avec fentes
	_base_plate = MeshInstance3D.new()
	_base_plate.name = "BasePlate"
	var plate_mesh = BoxMesh.new()
	plate_mesh.size = Vector3(2.4, 0.06, 2.4)
	var plate_mat = StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.22, 0.20, 0.22)
	plate_mat.metallic = 0.85
	plate_mat.roughness = 0.6
	_base_plate.mesh = plate_mesh
	_base_plate.position = Vector3(0, 0.03, 0)
	add_child(_base_plate)
	
	# 2. Pointes métalliques (initialement rétractées sous la dalle)
	_spikes_root = Node3D.new()
	_spikes_root.name = "SpikesRoot"
	_spikes_root.position = Vector3(0, -0.4, 0) # Rétracté
	add_child(_spikes_root)
	
	var spike_mat = StandardMaterial3D.new()
	spike_mat.albedo_color = Color(0.65, 0.65, 0.7)
	spike_mat.metallic = 0.95
	spike_mat.roughness = 0.3
	
	# Grille de 4x4 pointes métalliques acérées
	for ix in range(-1, 2):
		for iz in range(-1, 2):
			var spike = MeshInstance3D.new()
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.02
			cyl.bottom_radius = 0.09
			cyl.height = 0.65
			spike.mesh = cyl
			spike.material_override = spike_mat
			spike.position = Vector3(ix * 0.65, 0.32, iz * 0.65)
			_spikes_root.add_child(spike)
			
	# 3. Étincelles mécaniques lors de l'éjection
	_sparks = CPUParticles3D.new()
	_sparks.name = "Sparks"
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 0.95
	_sparks.amount = 14
	_sparks.lifetime = 0.35
	var spark_mesh = BoxMesh.new()
	spark_mesh.size = Vector3(0.04, 0.04, 0.08)
	var spark_mat = StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(2.5, 1.8, 0.5, 1.0)
	_sparks.mesh = spark_mesh
	_sparks.direction = Vector3(0, 1, 0)
	_sparks.spread = 45.0
	_sparks.initial_velocity_min = 2.0
	_sparks.initial_velocity_max = 4.5
	_sparks.position = Vector3(0, 0.1, 0)
	add_child(_sparks)

func _setup_trigger_area() -> void:
	_trigger_area = Area3D.new()
	_trigger_area.name = "TriggerArea"
	_trigger_area.collision_layer = 0
	_trigger_area.collision_mask = 1 # Détecte joueurs et corps physiques
	
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.2, 0.8, 2.2)
	col.shape = box
	col.position = Vector3(0, 0.4, 0)
	_trigger_area.add_child(col)
	add_child(_trigger_area)
	
	_trigger_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if is_active or is_cooling_down:
		return
	_trigger_trap()

func _trigger_trap() -> void:
	is_active = true
	
	# Bruit mécanique / cliquetis : délai avant éjection
	await get_tree().create_timer(trigger_delay).timeout
	
	# Éjection brutale des pointes vers le haut
	_sparks.restart()
	_sparks.emitting = true
	
	var tween = create_tween()
	tween.tween_property(_spikes_root, "position:y", 0.05, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Secousse caméra HD-2D
	var vp = get_viewport()
	if vp:
		var cam = vp.get_camera_3d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.16)
			
	# Infliger dégâts / recul aux entités présentes sur la dalle
	for body in _trigger_area.get_overlapping_bodies():
		if body is CharacterBody3D:
			# Impulsion de recul vers le haut / côté
			body.velocity += Vector3(randf_range(-1, 1), 3.5, randf_range(-1, 1)).normalized() * 3.0
			if body.has_method("take_hit"):
				body.take_hit(self)
				
	# Maintien des pointes sorties
	await get_tree().create_timer(active_duration).timeout
	
	# Rétraction lente sous la dalle
	var retract_tween = create_tween()
	retract_tween.tween_property(_spikes_root, "position:y", -0.4, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# Cooldown avant prochain réarmement
	is_cooling_down = true
	await get_tree().create_timer(reset_cooldown).timeout
	is_active = false
	is_cooling_down = false
