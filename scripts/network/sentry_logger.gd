class_name SentryLogger
extends Node

## Gestionnaire de logs et télémétrie d'erreurs (Sentry)

var sentry_dsn: String = ""
var _http_request: HTTPRequest

func _ready() -> void:
	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_load_env()
	
	if not sentry_dsn.is_empty():
		print("[Sentry] Initialisé avec DSN : ", sentry_dsn.substr(0, 15), "...")
	else:
		print("[Sentry] Mode local actif (SENTRY_DSN en attente).")

func _load_env() -> void:
	sentry_dsn = OS.get_environment("SENTRY_DSN")
	if sentry_dsn.is_empty() and FileAccess.file_exists("res://.env"):
		var f = FileAccess.open("res://.env", FileAccess.READ)
		if f:
			while not f.eof_reached():
				var line = f.get_line().strip_edges()
				if line.begins_with("SENTRY_DSN="):
					sentry_dsn = line.substr("SENTRY_DSN=".length()).strip_edges()

func capture_message(message: String, level: String = "info") -> void:
	print("[Sentry:%s] %s" % [level.to_upper(), message])
	if not sentry_dsn.is_empty():
		var payload = {
			"message": message,
			"level": level,
			"platform": "godot",
			"timestamp": Time.get_datetime_string_from_system(true)
		}
		_http_request.request(sentry_dsn, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))

func capture_error(error_message: String, context: String = "") -> void:
	push_error("[Action-RPG] " + error_message + " | Contexte : " + context)
	if not sentry_dsn.is_empty():
		# Formatage du payload Sentry minimal
		var payload = {
			"message": error_message,
			"level": "error",
			"platform": "other",
			"extra": {"context": context}
		}
		# Envoi HTTP asynchrone sans bloquer la boucle de jeu
		_http_request.request(sentry_dsn, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
