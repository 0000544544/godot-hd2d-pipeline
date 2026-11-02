class_name GroqNPCDialogue
extends Node

## Client de dialogue dynamique pour PNJ via l'API gratuite Groq Cloud
## Modèles recommandés : "llama-3.3-70b-versatile" ou "gemma2-9b-it"

signal dialogue_started()
signal dialogue_received(reply_text: String)
signal dialogue_error(error_message: String)

@export var api_key: String = ""
@export var model_name: String = "llama-3.3-70b-versatile"
@export_multiline var system_prompt: String = "Tu es un garde de village fatigué mais protecteur dans un univers médiéval fantastique HD-2D. Réponds de manière concise (1 à 3 phrases maximum) et expressive."
@export_range(0.0, 2.0) var temperature: float = 0.7

var _http_request: HTTPRequest
var _conversation_history: Array = []
const GROQ_URL: String = "https://api.groq.com/openai/v1/chat/completions"

func _ready() -> void:
	# Création dynamique du nœud HTTPRequest
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	
	# Récupération de la clé depuis l'environnement si vide
	if api_key.is_empty():
		api_key = OS.get_environment("GROQ_API_KEY")

	# Initialisation de l'historique avec le prompt système
	reset_dialogue()

func reset_dialogue() -> void:
	_conversation_history = [
		{"role": "system", "content": system_prompt}
	]

## Envoie un message du joueur au PNJ
func send_player_message(player_text: String) -> void:
	if api_key.is_empty():
		var err = "Clé d'API Groq manquante. Définissez la variable d'environnement GROQ_API_KEY ou le paramètre api_key."
		push_warning(err)
		dialogue_error.emit(err)
		return

	_conversation_history.append({"role": "user", "content": player_text})
	dialogue_started.emit()

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + api_key
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
		dialogue_error.emit(err_str)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code != 200:
		var err_body = body.get_string_from_utf8()
		var msg = "Erreur HTTP Groq (" + str(response_code) + ") : " + err_body
		push_error(msg)
		dialogue_error.emit(msg)
		return

	var parse_result = JSON.parse_string(body.get_string_from_utf8())
	if parse_result and parse_result.has("choices") and parse_result["choices"].size() > 0:
		var reply = parse_result["choices"][0]["message"]["content"]
		_conversation_history.append({"role": "assistant", "content": reply})
		dialogue_received.emit(reply)
	else:
		var parse_err = "Format de réponse inattendu depuis l'API Groq."
		push_error(parse_err)
		dialogue_error.emit(parse_err)
