class_name TorchFlicker
extends OmniLight3D

## Effet de vacillement naturel pour torche médiévale
## Fait osciller l'énergie et la portée lumineuse pour simuler une flamme vivante.

@export var base_energy: float = 2.2
@export var flicker_intensity: float = 0.35
@export var flicker_speed: float = 9.0

var _time: float = 0.0
var _offset: float = 0.0

func _ready() -> void:
	# Décalage aléatoire pour que toutes les torches ne vacillent pas à l'unisson
	_offset = randf_range(0.0, 100.0)

func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var t = _time + _offset
	# Combinaison d'ondes sinusoïdales à fréquences incommensurables
	var noise = sin(t) * 0.45 + sin(t * 2.37) * 0.35 + sin(t * 5.13) * 0.2
	light_energy = base_energy + noise * flicker_intensity
