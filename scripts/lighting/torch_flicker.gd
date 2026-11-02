class_name TorchFlicker
extends OmniLight3D

## Contrôleur d'effets visuels pour torche médiévale (Axe 6) :
## - Vacillement réaliste de l'énergie lumineuse et de la lumière volumétrique (Volumetric Fog)
## - Animation synchrone de pulsation du maillage de flamme (FlameCore)
## - Génération automatique ou synchronisation des particules d'étincelles (sparks) et de fumée (smoke)

@export var base_energy: float = 2.4
@export var flicker_intensity: float = 0.4
@export var flicker_speed: float = 8.5
@export var volumetric_fog_energy_base: float = 1.6
@export var enable_particles: bool = true

var _time: float = 0.0
var _offset: float = 0.0
var _flame_core: Node3D = null
var _sparks_particles: CPUParticles3D = null
var _smoke_particles: CPUParticles3D = null

func _ready() -> void:
	_offset = randf_range(0.0, 100.0)
	light_volumetric_fog_energy = volumetric_fog_energy_base
	
	var parent_torch = get_parent()
	if parent_torch:
		_flame_core = parent_torch.find_child("FlameCore", true, false)
		if enable_particles:
			_setup_torch_particles(parent_torch)

func _setup_torch_particles(parent_node: Node) -> void:
	# 1. Particules d'étincelles incandescents (Sparks)
	_sparks_particles = parent_node.find_child("TorchSparks", true, false) as CPUParticles3D
	if not _sparks_particles:
		_sparks_particles = CPUParticles3D.new()
		_sparks_particles.name = "TorchSparks"
		_sparks_particles.emitting = true
		_sparks_particles.amount = 14
		_sparks_particles.lifetime = 0.85
		_sparks_particles.preprocess = 0.5
		_sparks_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_sparks_particles.emission_sphere_radius = 0.08
		_sparks_particles.direction = Vector3(0, 1, 0)
		_sparks_particles.spread = 28.0
		_sparks_particles.gravity = Vector3(0, 0.4, 0)
		_sparks_particles.initial_velocity_min = 1.2
		_sparks_particles.initial_velocity_max = 2.2
		_sparks_particles.tangential_accel_min = -1.2
		_sparks_particles.tangential_accel_max = 1.2
		
		var spark_mesh = BoxMesh.new()
		spark_mesh.size = Vector3(0.035, 0.035, 0.035)
		var spark_mat = StandardMaterial3D.new()
		spark_mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		spark_mat.albedo_color = Color(2.6, 1.5, 0.35, 1.0) # Éclat HDR pour bloom
		spark_mesh.material = spark_mat
		_sparks_particles.mesh = spark_mesh
		_sparks_particles.position = Vector3(0, 1.05, 0)
		parent_node.add_child.call_deferred(_sparks_particles)

	# 2. Particules de volutes de fumée (Smoke)
	_smoke_particles = parent_node.find_child("TorchSmoke", true, false) as CPUParticles3D
	if not _smoke_particles:
		_smoke_particles = CPUParticles3D.new()
		_smoke_particles.name = "TorchSmoke"
		_smoke_particles.emitting = true
		_smoke_particles.amount = 8
		_smoke_particles.lifetime = 1.3
		_smoke_particles.preprocess = 0.8
		_smoke_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_smoke_particles.emission_sphere_radius = 0.06
		_smoke_particles.direction = Vector3(0, 1, 0)
		_smoke_particles.spread = 18.0
		_smoke_particles.gravity = Vector3(0, 0.85, 0)
		_smoke_particles.initial_velocity_min = 0.5
		_smoke_particles.initial_velocity_max = 1.1
		
		var smoke_mesh = SphereMesh.new()
		smoke_mesh.radius = 0.10
		smoke_mesh.height = 0.20
		var smoke_mat = StandardMaterial3D.new()
		smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
		smoke_mat.albedo_color = Color(0.18, 0.18, 0.22, 0.25)
		smoke_mesh.material = smoke_mat
		_smoke_particles.mesh = smoke_mesh
		_smoke_particles.position = Vector3(0, 1.18, 0)
		parent_node.add_child.call_deferred(_smoke_particles)

func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var t = _time + _offset
	var noise = sin(t) * 0.45 + sin(t * 2.37) * 0.35 + sin(t * 5.13) * 0.2
	var current_energy = base_energy + noise * flicker_intensity
	light_energy = current_energy
	light_volumetric_fog_energy = volumetric_fog_energy_base * (current_energy / base_energy)

	if _flame_core and is_instance_valid(_flame_core):
		var scale_factor = 1.0 + (noise * flicker_intensity * 0.16)
		_flame_core.scale = Vector3(scale_factor, scale_factor * 1.12, scale_factor)
