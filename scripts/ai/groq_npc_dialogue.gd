class_name GroqNPCDialogue
extends Node

## Client de dialogue dynamique pour PNJ via l'API Groq Cloud
## Détecte dynamiquement l'état du coffre doré (scellé / ouvert) pour enrichir le prompt système.
## Charge automatiquement GROQ_API_KEY depuis res://.env ou les variables d'environnement.
## Fournit des replis narratifs immersifs en cas d'absence de clé ou d'erreur réseau.

signal dialogue_started()
signal dialogue_received(reply_text: String)
signal dialogue_error(error_message: String)

@export var api_key: String = ""
@export var model_name: String = "qwen/qwen3.8-27b"
@export var chest_node: Node3D = null
@export_multiline var system_prompt: String = "Tu es Maître Eldrin, l'archiviste du sanctuaire. Tu veilles sur ce lieu antique. Réponds avec sagesse, mystère et brièveté (1 à 3 phrases maximum) au chevalier qui t'aborde."
@export_range(0.0, 2.0) var temperature: float = 0.7

var _http_request: HTTPRequest
var _conversation_history: Array = []
const GROQ_URL: String = "https://api.groq.com/openai/v1/chat/completions"

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	if api_key.is_empty():
		api_key = _get_api_key_from_env()

	reset_dialogue()

func get_chest_node() -> Node:
	if chest_node and is_instance_valid(chest_node):
		return chest_node
	var chest = get_tree().get_first_node_in_group("gold_chest")
	if not chest:
		chest = get_tree().root.find_child("Chest_Gold", true, false)
	return chest

func is_chest_opened() -> bool:
	var chest = get_chest_node()
	if chest and "is_opened" in chest:
		return bool(chest.is_opened)
	return false

func get_effective_system_prompt() -> String:
	var prompt = system_prompt
	if is_chest_opened():
		prompt += " Le chevalier vient tout juste d'ouvrir le coffre doré sous tes yeux. Réagis directement à cet événement, félicite-le ou mets-le en garde sur les secrets qu'il vient de libérer."
	else:
		prompt += " Le coffre doré ancestral dans la cour est toujours scellé. Tu peux éveiller la curiosité du chevalier à son sujet."
	return prompt

func reset_dialogue() -> void:
	_conversation_history = [
		{"role": "system", "content": get_effective_system_prompt()}
	]

func _get_api_key_from_env() -> String:
	var key = OS.get_environment("GROQ_API_KEY")
	if not key.is_empty():
		return key.strip_edges()
	
	# Lecture dans res://.env
	if FileAccess.file_exists("res://.env"):
		var file = FileAccess.open("res://.env", FileAccess.READ)
		if file:
			while not file.eof_reached():
				var line = file.get_line().strip_edges()
				if line.begins_with("GROQ_API_KEY="):
					var val = line.substr("GROQ_API_KEY=".length()).strip_edges()
					if not val.is_empty() and not val.begins_with("#"):
						return val
	return ""

## Envoie un message du joueur au PNJ avec conscience dynamique de l'état du coffre
func send_player_message(player_text: String) -> void:
	# Re-vérification de la clé au moment de l'appel
	if api_key.is_empty():
		api_key = _get_api_key_from_env()

	dialogue_started.emit()

	# Mise à jour immédiate du prompt système selon l'état actuel du coffre
	var current_system_prompt = get_effective_system_prompt()
	if _conversation_history.is_empty():
		_conversation_history.append({"role": "system", "content": current_system_prompt})
	else:
		_conversation_history[0] = {"role": "system", "content": current_system_prompt}

	# Si aucune clé n'est configurée, fournir une réponse de repli narrative adaptée
	if api_key.is_empty():
		var fallbacks = []
		if is_chest_opened():
			fallbacks = [
				"Par les anciens dieux ! Tu as osé briser le scellé du coffre doré... Ce qui était endormi s'éveille. Prends garde aux bénédictions qui ressemblent à des malédictions, chevalier.",
				"La lueur dorée du coffre baigne à nouveau les dalles du sanctuaire. Tu as fait preuve d'une témérité remarquable en libérant ses reliques.",
				"Le trésor des temps anciens t'appartient désormais. Veille à ne point succomber à l'ivresse du pouvoir qu'il confère."
			]
		else:
			fallbacks = [
				"Salutations, noble voyageur. Les pierres de cette cour gardent la mémoire des siècles passés. Le coffre doré scellé au nord renferme une antique bénédiction : approche-toi et presse [E] pour l'ouvrir.\n\n[color=#e0a838]✦ Pour dialoguer avec l'IA en direct, renseignez GROQ_API_KEY dans votre fichier .env[/color]",
				"La lumière des torches veille sur notre sanctuaire. Prends le temps d'éprouver ton épée et ton esquive, car le chemin est semé d'épreuves.\n\n[color=#e0a838]✦ Connectez votre clé Groq gratuite dans .env pour débloquer les échanges infinis.[/color]",
				"Je suis Maître Eldrin, gardien des archives. Les runes s'agitent... Si tu cherches un trésor, dirige-toi vers le nord, près de l'arche brisée.\n\n[color=#e0a838]✦ GROQ_API_KEY activable dans godot-hd2d-pipeline/.env[/color]"
			]
		var chosen = fallbacks[randi() % fallbacks.size()]
		var timer = get_tree().create_timer(0.35)
		timer.timeout.connect(func(): dialogue_received.emit(chosen))
		return

	_conversation_history.append({"role": "user", "content": player_text})

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key,
		"User-Agent: GodotGame/1.0"
	]

	var payload = {
		"model": model_name,
		"messages": _conversation_history,
		"temperature": temperature,
		"max_tokens": 150
	}

	var json_body = JSON.stringify(payload)
	var error = _http_request.request(GROQ_URL, headers, HTTPClient.METHOD_POST, json_body)
	if error != OK:
		var err_str = "Échec du déclenchement de la requête HTTP : " + str(error)
		push_error(err_str)
		_emit_fallback_on_error()

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var err_body = body.get_string_from_utf8()
		push_error("Erreur HTTP Groq (" + str(response_code) + ") : " + err_body)
		_emit_fallback_on_error()
		return

	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	if parse_result and parse_result.has("choices") and parse_result["choices"].size() > 0:
		var reply = parse_result["choices"][0]["message"]["content"]
		_conversation_history.append({"role": "assistant", "content": reply})
		dialogue_received.emit(reply)
	else:
		_emit_fallback_on_error()

func _emit_fallback_on_error() -> void:
	if is_chest_opened():
		dialogue_received.emit("Maître Eldrin contemple la lueur dorée : 'Le sceau est rompu... Même si les flux éthérés vacillent, ton courage devant le coffre force le respect.'")
	else:
		dialogue_received.emit("Les échos éthérés faiblissent... Maître Eldrin hoche la tête avec gravité : 'La magie vacille, voyageur, mais ma foi en ta quête demeure inébranlable.'")
