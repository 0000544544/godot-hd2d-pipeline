class_name LootItem
extends Node3D

## Butin émergeant des objets détruits (Pièce d'or ou Potion)
## - Animation d'émergence (pop vertical puis retombée douce)
## - Rotation et flottement sinusoïdal en attente
## - Détection de proximité et aspiration / ramassage automatique par le Chevalier

enum LootType {
	COIN,
	POTION
}

@export var loot_type: LootType = LootType.COIN
@export var pickup_distance: float = 1.6

var is_collected: bool = false
var _mesh_node: MeshInstance3D
var _light_node: OmniLight3D
var _label_node: Label3D
var _base_y: float = 0.4
var _anim_time: float = 0.0
var _is_popping: bool = true

func _ready() -> void:
	_build_visuals()
	_play_spawn_pop_animation()

func _build_visuals() -> void:
	_mesh_node = MeshInstance3D.new()
	_mesh_node.name = "LootMesh"
	
	var mat = StandardMaterial3D.new()
	mat.roughness = 0.2
	
	if loot_type == LootType.COIN:
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.24
		cyl.bottom_radius = 0.24
		cyl.height = 0.07
		_mesh_node.mesh = cyl
		_mesh_node.rotation_degrees.x = 90.0
		mat.albedo_color = Color(1.0, 0.82, 0.18, 1.0)
		mat.metallic = 0.95
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.7, 0.15)
		mat.emission_energy_multiplier = 0.6
	else:
		var sph = SphereMesh.new()
		sph.radius = 0.22
		sph.height = 0.44
		_mesh_node.mesh = sph
		mat.albedo_color = Color(0.92, 0.2, 0.32, 1.0)
		mat.metallic = 0.2
		mat.roughness = 0.1
		mat.emission_enabled = true
		mat.emission = Color(0.95, 0.15, 0.25)
		mat.emission_energy_multiplier = 0.9
	
	_mesh_node.material_override = mat
	add_child(_mesh_node)
	
	# Halo lumineux
	_light_node = OmniLight3D.new()
	_light_node.name = "LootGlow"
	_light_node.light_color = Color(1.0, 0.85, 0.3) if loot_type == LootType.COIN else Color(1.0, 0.3, 0.4)
	_light_node.light_energy = 1.4
	_light_node.omni_range = 2.6
	add_child(_light_node)
	
	# Label flottant annonçant la récompense
	_label_node = Label3D.new()
	_label_node.name = "LootLabel"
	_label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_node.no_depth_test = true
	_label_node.font_size = 28
	_label_node.outline_size = 8
	_label_node.outline_modulate = Color(0.05, 0.05, 0.08, 0.95)
	_label_node.modulate = Color(1.0, 0.9, 0.4, 1.0) if loot_type == LootType.COIN else Color(1.0, 0.5, 0.6, 1.0)
	_label_node.text = "+25 Or ✦" if loot_type == LootType.COIN else "+50 PV ❤"
	_label_node.position = Vector3(0, 0.5, 0)
	_label_node.visible = false
	add_child(_label_node)

func _play_spawn_pop_animation() -> void:
	_is_popping = true
	var start_y = position.y
	_base_y = start_y + 0.38
	
	var tween = create_tween()
	# Pop vers le haut
	tween.tween_property(self, "position:y", start_y + 0.9, 0.24)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	# Retombée douce avec rebond
	tween.tween_property(self, "position:y", _base_y, 0.30)\
		.set_trans(Tween.TRANS_BOUNCE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): _is_popping = false)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	_anim_time += delta
	# Rotation continue
	if _mesh_node:
		_mesh_node.rotation.y += 3.2 * delta
	
	# Flottement doux sinusoïdal
	if not _is_popping:
		position.y = _base_y + sin(_anim_time * 3.6) * 0.08
	
	# Détection de proximité du Chevalier pour ramassage automatique
	_check_player_pickup()

func _check_player_pickup() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player = players[0] as Node3D
	if not is_instance_valid(player):
		return
	
	var dist = global_position.distance_to(player.global_position)
	if dist <= pickup_distance:
		collect(player)

func collect(collector: Node3D) -> void:
	if is_collected:
		return
	is_collected = true
	
	# Afficher le badge flottant qui s'élève
	if _label_node:
		_label_node.visible = true
	
	var tween = create_tween().set_parallel(true)
	# Aspiration vers le chevalier
	var target_pos = collector.global_position + Vector3(0, 1.2, 0)
	tween.tween_property(self, "global_position", target_pos, 0.32)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector3.ZERO, 0.32)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	
	# Le label monte et s'estompe
	if _label_node:
		var label_tween = create_tween()
		label_tween.tween_property(_label_node, "position:y", 1.4, 0.55)
		label_tween.parallel().tween_property(_label_node, "modulate:a", 0.0, 0.55)
	
	# Suppression du nœud une fois absorbé
	get_tree().create_timer(0.6).timeout.connect(func():
		queue_free()
	)
