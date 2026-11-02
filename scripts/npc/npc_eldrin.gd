class_name NPCEldrin
extends StaticBody3D

## Contrôleur d'animation, d'orientation et de dialogue pour Maître Eldrin (Mage)
## - Bouclage forcé de l'animation d'attente (Idle)
## - Orientation par défaut à -35° et suivi dynamique (lerp_angle vers le joueur)
## - Déclenchement du dialogue IA [E] et connexion à DialogueBox & Groq Cloud

@export var anim_player: AnimationPlayer
@export var model_root: Node3D
@export var player_target: Node3D
@export var groq_client: GroqNPCDialogue
@export var interactable: Area3D

@export_group("Orientation & Regard Dynamique")
@export var default_rotation_degrees: float = -35.0
@export var detection_range: float = 5.0
@export var rotation_speed: float = 4.0

var _default_rotation_rad: float = 0.0
var _dialogue_box: CanvasLayer = null

func _ready() -> void:
	if not model_root and has_node("Mage"):
		model_root = get_node("Mage")
	
	if not anim_player and model_root:
		anim_player = model_root.find_child("AnimationPlayer", true, false)
	
	if not groq_client and has_node("GroqDialogueClient"):
		groq_client = get_node("GroqDialogueClient") as GroqNPCDialogue
	
	if not interactable:
		interactable = find_child("InteractableArea", true, false) as Area3D
	
	if interactable:
		interactable.prompt_text = "[E] Parler"
		interactable.prompt_offset = Vector3(0, 2.1, 0)
		interactable.interacted.connect(_on_interacted)
	
	if groq_client:
		groq_client.dialogue_received.connect(_on_dialogue_received)
		groq_client.dialogue_error.connect(_on_dialogue_error)
	
	# Bouclage forcé de l'animation Idle
	if anim_player and anim_player.has_animation("Idle"):
		var anim: Animation = anim_player.get_animation("Idle")
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle")
	
	_default_rotation_rad = deg_to_rad(default_rotation_degrees)
	if model_root:
		model_root.rotation.y = _default_rotation_rad

func _physics_process(delta: float) -> void:
	_update_gaze(delta)

## Oriente doucement le mage vers le joueur s'il est à portée, ou revient à la rotation par défaut
func _update_gaze(delta: float) -> void:
	if not model_root:
		return
	
	if not player_target or not is_instance_valid(player_target):
		player_target = get_node_or_null("../Player")
		if not player_target:
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				player_target = players[0]
	
	var target_rot_y: float = deg_to_rad(default_rotation_degrees)
	
	if player_target and is_instance_valid(player_target):
		var to_player: Vector3 = player_target.global_position - global_position
		to_player.y = 0.0
		var distance: float = to_player.length()
		
		# Si le joueur est à moins de detection_range (5 mètres)
		if distance <= detection_range and distance > 0.05:
			target_rot_y = atan2(to_player.x, to_player.z)
	
	# Interpolation angulaire douce sans à-coups
	var weight: float = clampf(rotation_speed * delta, 0.0, 1.0)
	model_root.rotation.y = lerp_angle(model_root.rotation.y, target_rot_y, weight)

func _on_interacted(player: Node3D) -> void:
	if not _dialogue_box:
		_dialogue_box = get_tree().root.find_child("DialogueBox", true, false)
	
	if _dialogue_box and _dialogue_box.has_method("open_dialogue"):
		_dialogue_box.open_dialogue("Maître Eldrin", "...", player, interactable)
	
	if groq_client:
		var greeting = "Salutations, Maître Eldrin."
		if groq_client.is_chest_opened():
			greeting = "Maître Eldrin, j'ai ouvert le coffre doré scellé au nord de la cour."
		groq_client.send_player_message(greeting)
	else:
		_on_dialogue_received("Salutations, noble voyageur. Je veille sur ce sanctuaire antique.")

func _on_dialogue_received(reply_text: String) -> void:
	if not _dialogue_box:
		_dialogue_box = get_tree().root.find_child("DialogueBox", true, false)
	if _dialogue_box and _dialogue_box.get("is_active"):
		_dialogue_box.display_text(reply_text)

func _on_dialogue_error(error_msg: String) -> void:
	if not _dialogue_box:
		_dialogue_box = get_tree().root.find_child("DialogueBox", true, false)
	if _dialogue_box and _dialogue_box.get("is_active"):
		_dialogue_box.display_text("Les flux magiques sont perturbés... (" + error_msg + ")")
