extends Node3D

var _frames: int = 0
var _take_screenshot: bool = false

func _ready() -> void:
	for arg in OS.get_cmdline_args():
		if arg == "--screenshot":
			_take_screenshot = true

func _process(_delta: float) -> void:
	_frames += 1
	if _take_screenshot and _frames == 60:
		var img = get_viewport().get_texture().get_image()
		if img:
			img.save_png("screenshot_demo_hd2d.png")
			print("[OK] Capture d'ecran HD-2D sauvegardee : screenshot_demo_hd2d.png")
		get_tree().quit(0)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		get_tree().quit(0)
