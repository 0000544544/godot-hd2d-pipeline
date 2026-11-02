class_name Interactable
extends Area3D

## Composant universel d'interaction (Coffre, PNJ, Portes)
## Affiche un badge flottant stylisé [E] lorsque le joueur s'approche à moins de 2.5m.

signal interacted(player: Node3D)

@export var prompt_text: String = "[E] Interagir"
@export var prompt_offset: Vector3 = Vector3(0, 1.5, 0)
@export var is_interactable: bool = true

var _label: Label3D
var _current_player: Node3D = null

func _ready() -> void:
	monitoring = true
	monitorable = true
	
	# Recherche ou création dynamique du Label3D flottant
	_label = find_child("PromptLabel", true, false) as Label3D
	if not _label:
		_label = Label3D.new()
		_label.name = "PromptLabel"
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label.no_depth_test = true
		_label.render_priority = 10
		_label.font_size = 32
		_label.outline_size = 10
		_label.outline_modulate = Color(0.06, 0.07, 0.12, 0.95)
		_label.modulate = Color(1.0, 0.88, 0.42, 1.0) # Lueur dorée HD-2D
		_label.position = prompt_offset
		add_child(_label)
	
	_label.text = prompt_text
	_label.visible = false
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_prompt(new_text: String) -> void:
	prompt_text = new_text
	if _label:
		_label.text = new_text

func set_active(active: bool) -> void:
	is_interactable = active
	if not active and _label:
		_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not is_interactable:
		return
	if body.is_in_group("player") or body.name == "Player":
		_current_player = body
		if _label:
			_label.text = prompt_text
			_label.visible = true
		if body.has_method("set_current_interactable"):
			body.set_current_interactable(self)

func _on_body_exited(body: Node3D) -> void:
	if body == _current_player or body.is_in_group("player"):
		if _label:
			_label.visible = false
		if body.has_method("clear_current_interactable"):
			body.clear_current_interactable(self)
		_current_player = null

func trigger_interaction(player: Node3D) -> void:
	if not is_interactable:
		return
	interacted.emit(player)
