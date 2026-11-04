class_name NPCCryptMaster
extends CharacterBody3D

## PNJ Maître de la Crypte (Modèle 3D Mage KayKit)
## Connecté à Groq Cloud pour dialogue dynamique et Supabase pour sauvegarde.

signal interaction_opened()

@onready var anim_player: AnimationPlayer = $Model/Mage/AnimationPlayer
@onready var prompt_label: Label3D = $PromptLabel
@onready var sfx_greeting: AudioStreamPlayer3D = $SFXGreeting
@onready var groq_client: GroqNPCDialogue = $GroqDialogue

var player_in_range: bool = false
var is_chatting: bool = false

func _ready() -> void:
	add_to_group("npc")
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")

	if prompt_label:
		prompt_label.visible = false

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_chatting:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
			start_conversation()

func start_conversation() -> void:
	is_chatting = true
	if prompt_label:
		prompt_label.visible = false

	# Bruitage d'accueil
	if sfx_greeting:
		sfx_greeting.play()

	# Animation d'interaction du mage
	if anim_player and anim_player.has_animation("Interact"):
		anim_player.play("Interact")

	interaction_opened.emit()
	
	# Premier message d'accueil généré ou de salutation
	if groq_client:
		groq_client.send_player_message("Salutations, Maître de la Crypte. Que protégez-vous en ce lieu sombre ?")

func close_conversation() -> void:
	is_chatting = false
	if player_in_range and prompt_label:
		prompt_label.visible = true
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")
