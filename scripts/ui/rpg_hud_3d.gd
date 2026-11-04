class_name RPGHUD3D
extends CanvasLayer

## Interface HUD RPG Stylisée 3D Dark Fantasy
## Intègre portraits ComfyUI, barres PV/Mana, inventaire rapide, dialogue Groq et statut Supabase.

@export var player_node: Player3D = null
@export var npc_node: NPCCryptMaster = null
@export var supabase_node: SupabaseManager = null

# Références UI
@onready var portrait_knight: TextureRect = $TopLeft/Panel/HBox/Portrait
@onready var hp_bar: ProgressBar = $TopLeft/Panel/HBox/VBox/HPBar
@onready var hp_label: Label = $TopLeft/Panel/HBox/VBox/HPBar/Label
@onready var mana_bar: ProgressBar = $TopLeft/Panel/HBox/VBox/ManaBar
@onready var mana_label: Label = $TopLeft/Panel/HBox/VBox/ManaBar/Label
@onready var gold_label: Label = $TopLeft/Panel/HBox/VBox/StatsHBox/GoldLabel
@onready var kills_label: Label = $TopLeft/Panel/HBox/VBox/StatsHBox/KillsLabel
@onready var cloud_badge: Label = $TopLeft/Panel/HBox/VBox/CloudBadge

# Dialogue UI
@onready var dialogue_panel: PanelContainer = $DialogueContainer
@onready var dialogue_portrait: TextureRect = $DialogueContainer/VBox/ContentHBox/Portrait
@onready var dialogue_name: Label = $DialogueContainer/VBox/ContentHBox/TextVBox/SpeakerName
@onready var dialogue_text: RichTextLabel = $DialogueContainer/VBox/ContentHBox/TextVBox/DialogueText
@onready var player_input: LineEdit = $DialogueContainer/VBox/InputHBox/PlayerInput
@onready var send_button: Button = $DialogueContainer/VBox/InputHBox/SendButton
@onready var close_button: Button = $DialogueContainer/VBox/HeaderHBox/CloseButton

# Inventaire UI
@onready var slot_sword: TextureRect = $BottomRight/Panel/HBox/SlotSword/Icon
@onready var slot_potion: TextureRect = $BottomRight/Panel/HBox/SlotPotion/Icon

var _typewriter_tween: Tween = null
var _last_full_text: String = ""

func _ready() -> void:
	layer = 10
	dialogue_panel.visible = false
	
	if not player_node:
		player_node = get_tree().get_first_node_in_group("player") as Player3D
	if not npc_node:
		npc_node = get_tree().get_first_node_in_group("npc") as NPCCryptMaster
	if not supabase_node:
		supabase_node = get_tree().root.find_child("SupabaseManager", true, false) as SupabaseManager

	# Connexion signaux joueur
	if player_node:
		player_node.stats_changed.connect(_on_player_stats_changed)
		_on_player_stats_changed(player_node.hp, player_node.max_hp, player_node.mana, player_node.max_mana, player_node.gold)

	# Connexion signaux NPC
	if npc_node:
		npc_node.interaction_opened.connect(open_dialogue)
		var groq = npc_node.find_child("GroqDialogue", true, false) as GroqNPCDialogue
		if groq:
			groq.dialogue_started.connect(_on_dialogue_started)
			groq.dialogue_received.connect(_on_dialogue_received)
			groq.dialogue_error.connect(_on_dialogue_error)

	# Connexion boutons dialogue
	send_button.pressed.connect(_on_send_pressed)
	close_button.pressed.connect(close_dialogue)
	player_input.text_submitted.connect(func(_t): _on_send_pressed())

	# Connexion sauvegarde Supabase
	if supabase_node:
		supabase_node.save_completed.connect(_on_supabase_save_completed)
		# Sauvegarde d'initialisation
		supabase_node.save_state(5, 0, 0, "Début de la partie")

func _on_player_stats_changed(hp: int, max_hp: int, mana: int, max_mana: int, gold: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = hp
	if hp_label:
		hp_label.text = "PV : %d / %d" % [hp, max_hp]
	if mana_bar:
		mana_bar.max_value = max_mana
		mana_bar.value = mana
	if mana_label:
		mana_label.text = "Mana : %d / %d" % [mana, max_mana]
	if gold_label:
		gold_label.text = "✦ Or : %d" % gold
	if kills_label and player_node:
		kills_label.text = "☠ Vaincus : %d" % player_node.enemies_killed

	# Sauvegarde automatique vers Supabase
	if supabase_node and player_node:
		supabase_node.save_state(hp, gold, player_node.enemies_killed, "Stats mises à jour")

func _on_supabase_save_completed(_is_cloud: bool, message: String) -> void:
	if cloud_badge:
		cloud_badge.text = "● " + message
		cloud_badge.modulate = Color(0.4, 1.0, 0.5, 1.0)
		var tween = create_tween()
		tween.tween_property(cloud_badge, "modulate:a", 0.6, 2.0)

func open_dialogue() -> void:
	dialogue_panel.visible = true
	player_input.grab_focus()
	player_input.text = ""

func close_dialogue() -> void:
	dialogue_panel.visible = false
	if npc_node:
		npc_node.close_conversation()

func _on_send_pressed() -> void:
	var msg = player_input.text.strip_edges()
	if msg.is_empty():
		return
	
	player_input.text = ""
	dialogue_text.text = "[color=#888899][i]Réflexion de Maître Eldrin...[/i][/color]"
	
	if npc_node:
		var groq = npc_node.find_child("GroqDialogue", true, false) as GroqNPCDialogue
		if groq:
			groq.send_player_message(msg)

func _on_dialogue_started() -> void:
	dialogue_text.text = "[color=#888899][i]Maître Eldrin médite les flux arcaniques...[/i][/color]"

func _on_dialogue_received(reply: String) -> void:
	_last_full_text = reply
	dialogue_text.text = reply
	dialogue_text.visible_ratio = 0.0
	
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
		
	_typewriter_tween = create_tween()
	var duration = clamp(reply.length() * 0.025, 0.4, 2.5)
	_typewriter_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)

func _on_dialogue_error(err: String) -> void:
	dialogue_text.text = "[color=#ff6666]" + err + "[/color]"

func _unhandled_input(event: InputEvent) -> void:
	if dialogue_panel.visible:
		if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
			close_dialogue()
