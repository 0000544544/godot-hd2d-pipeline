class_name RelicPedestal
extends Node3D

## Relique antique flottante au centre de la crypte avec lueur éthérée bleue
## Rotation douce et lévitation sinusoïdale

@export var rotation_speed: float = 1.2
@export var float_amplitude: float = 0.08
@export var float_speed: float = 2.2

@onready var crystal: Node3D = $Crystal
@onready var light: OmniLight3D = $OmniLight3D

var _base_y: float = 1.75
var _time: float = 0.0

func _ready() -> void:
	if crystal:
		_base_y = crystal.position.y

func _process(delta: float) -> void:
	_time += delta
	if crystal:
		crystal.rotation.y += rotation_speed * delta
		crystal.position.y = _base_y + sin(_time * float_speed) * float_amplitude
	
	if light:
		light.light_energy = 2.4 + sin(_time * 3.5) * 0.4
