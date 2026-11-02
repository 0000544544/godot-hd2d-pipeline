class_name DialogueBox
extends CanvasLayer

## Interface de dialogue médiévale HD-2D avec effet machine à écrire (Typewriter)
## Bloque les déplacements du joueur pendant la conversation et supporte la fermeture par Espace/Échap/E.
## Masque automatiquement les invites d'interaction flottantes pendant la discussion.

signal dialogue_opened()
signal dialogue_closed()

@export var typewriter_chars_per_second: float = 38.0

var is_active: bool = false
var _player: Node = null
var _active_interactable: Area3D = null
var _speaker_label: Label
var _body_label: RichTextLabel
var _footer_label: Label
var _panel_container: PanelContainer
var _typewriter_tween: Tween = null
var _full_text: String = ""

func _ready() -> void:
	layer = 100
	visible = false
	_build_ui_if_needed()

func _build_ui_if_needed() -> void:
	if has_node("DialoguePanel"):
		_panel_container = get_node("DialoguePanel")
		_speaker_label = _panel_container.find_child("SpeakerLabel", true, false)
		_body_label = _panel_container.find_child("BodyLabel", true, false)
		_footer_label = _panel_container.find_child("FooterLabel", true, false)
		return

	# Création dynamique de l'interface médiévale
	_panel_container = PanelContainer.new()
	_panel_container.name = "DialoguePanel"
	_panel_container.anchor_left = 0.12
	_panel_container.anchor_right = 0.88
	_panel_container.anchor_top = 0.72
	_panel_container.anchor_bottom = 0.94
	
	# Stylebox médiéval : Fond sombre bleuté et liseré doré
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	style.border_color = Color(0.86, 0.72, 0.32, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 16
	style.content_margin_bottom = 14
	_panel_container.add_theme_stylebox_override("panel", style)
	add_child(_panel_container)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel_container.add_child(vbox)

	# Nom de l'interlocuteur
	_speaker_label = Label.new()
	_speaker_label.name = "SpeakerLabel"
	_speaker_label.text = "Maître Eldrin"
	_speaker_label.modulate = Color(1.0, 0.85, 0.38, 1.0)
	_speaker_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_speaker_label)

	# Corps du dialogue
	_body_label = RichTextLabel.new()
	_body_label.name = "BodyLabel"
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.bbcode_enabled = true
	_body_label.scroll_active = false
	_body_label.modulate = Color(0.93, 0.91, 0.86, 1.0)
	_body_label.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(_body_label)

	# Invite de fermeture
	_footer_label = Label.new()
	_footer_label.name = "FooterLabel"
	_footer_label.text = "[Espace / Échap] Continuer"
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer_label.modulate = Color(0.65, 0.65, 0.72, 0.85)
	_footer_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_footer_label)

func open_dialogue(speaker: String, text: String, player: Node = null, interactable_source: Area3D = null) -> void:
	_build_ui_if_needed()
	is_active = true
	visible = true
	
	_player = player
	if not _player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0]
	
	if _player:
		_player.set("is_dialogue_open", true)
		if _player.has_method("_change_state"):
			_player._change_state(5) # State.INTERACT
	
	# Référence à l'interactable source pour masquer son badge d'interaction
	if interactable_source:
		_active_interactable = interactable_source
	elif _player and "current_interactable" in _player and _player.current_interactable:
		_active_interactable = _player.current_interactable
	
	# Masquer explicitement le badge d'interaction
	if _active_interactable and is_instance_valid(_active_interactable):
		if _active_interactable.has_method("hide_prompt"):
			_active_interactable.hide_prompt()
		else:
			var lbl = _active_interactable.find_child("PromptLabel", true, false)
			if lbl:
				lbl.visible = false
	
	# Masquer également tout autre badge interactable affiché à l'écran
	get_tree().call_group("interactables", "hide_prompt")
	
	dialogue_opened.emit()
	
	_speaker_label.text = speaker
	display_text(text)

func display_text(text: String) -> void:
	_build_ui_if_needed()
	_full_text = text
	_body_label.text = text
	_body_label.visible_ratio = 0.0
	
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	
	var duration: float = max(0.4, float(text.length()) / typewriter_chars_per_second)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(_body_label, "visible_ratio", 1.0, duration)

func close_dialogue() -> void:
	if not is_active:
		return
	
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	
	is_active = false
	visible = false
	
	if _player:
		_player.set("is_dialogue_open", false)
		if _player.has_method("_change_state"):
			_player._change_state(0) # State.IDLE
		_player = null
	
	# Rétablir la visibilité du badge uniquement si le joueur se trouve toujours dans la zone de détection
	if _active_interactable and is_instance_valid(_active_interactable):
		if _active_interactable.has_method("restore_prompt"):
			_active_interactable.restore_prompt()
		else:
			var lbl = _active_interactable.find_child("PromptLabel", true, false)
			if lbl and _active_interactable.get("is_interactable") and _active_interactable.get("_current_player") != null:
				lbl.visible = true
		_active_interactable = null
	
	# Restaurer l'affichage pour tout interactable dont le joueur occupe toujours la zone
	get_tree().call_group("interactables", "restore_prompt")
	
	dialogue_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER, KEY_E] or \
		   event.physical_keycode in [KEY_SPACE, KEY_ESCAPE, KEY_ENTER, KEY_E]:
			_on_advance_requested()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_advance_requested()
			get_viewport().set_input_as_handled()

func _on_advance_requested() -> void:
	# Si la machine à écrire n'a pas fini, afficher tout le texte immédiatement
	if _body_label.visible_ratio < 0.98:
		if _typewriter_tween and _typewriter_tween.is_valid():
			_typewriter_tween.kill()
		_body_label.visible_ratio = 1.0
	else:
		# Sinon fermer le dialogue
		close_dialogue()
