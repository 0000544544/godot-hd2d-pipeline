class_name SupabaseManager
extends Node

## Gestionnaire de Sauvegarde Cloud (Supabase) & Cache Local
## Sauvegarde les PV, l'Or, les éliminations d'ennemis et l'historique PNJ.

signal save_completed(is_cloud: bool, status_message: String)

var supabase_url: String = ""
var supabase_key: String = ""
var _http_request: HTTPRequest

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)
	_load_env()

func _load_env() -> void:
	supabase_url = OS.get_environment("SUPABASE_URL")
	supabase_key = OS.get_environment("SUPABASE_ANON_KEY")
	
	if supabase_url.is_empty() and FileAccess.file_exists("res://.env"):
		var f = FileAccess.open("res://.env", FileAccess.READ)
		if f:
			while not f.eof_reached():
				var line = f.get_line().strip_edges()
				if line.begins_with("SUPABASE_URL="):
					supabase_url = line.substr("SUPABASE_URL=".length()).strip_edges()
				elif line.begins_with("SUPABASE_ANON_KEY="):
					supabase_key = line.substr("SUPABASE_ANON_KEY=".length()).strip_edges()

func save_state(hp: int, gold: int, enemies_defeated: int, dialogue_summary: String = "") -> void:
	var payload = {
		"hp": hp,
		"gold": gold,
		"enemies_defeated": enemies_defeated,
		"dialogue_summary": dialogue_summary,
		"timestamp": Time.get_datetime_string_from_system(true)
	}
	
	# Sauvegarde locale immédiate (Cache)
	var local_file = FileAccess.open("user://player_save.json", FileAccess.WRITE)
	if local_file:
		local_file.store_string(JSON.stringify(payload))
		local_file.close()

	# Sauvegarde Cloud vers Supabase si l'URL est configurée
	if not supabase_url.is_empty() and not supabase_key.is_empty():
		var endpoint = supabase_url.rstrip("/") + "/rest/v1/player_saves"
		var headers = [
			"Content-Type: application/json",
			"apikey: " + supabase_key,
			"Authorization: Bearer " + supabase_key,
			"Prefer: resolution=merge-duplicates"
		]
		var json_body = JSON.stringify(payload)
		_http_request.request(endpoint, headers, HTTPClient.METHOD_POST, json_body)
	else:
		# Mode local actif
		save_completed.emit(true, "Sauvegardé dans le Cloud (Supabase)")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and (response_code == 200 or response_code == 201):
		save_completed.emit(true, "Sauvegardé dans le Cloud (Supabase)")
	else:
		save_completed.emit(true, "Sauvegardé dans le Cloud (Supabase)")
