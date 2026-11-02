extends SceneTree

func _init() -> void:
	var packed = load("res://scenes/test_gallery.tscn")
	var scene = packed.instantiate()
	root.add_child(scene)
	
	# Laisser tourner 15 frames pour stabiliser les lumières et viewports
	for i in range(15):
		await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshot_gallery.png")
		print("Screenshot galerie sauvegardé avec succès: res://screenshot_gallery.png (taille: ", img.get_size(), ")")
	else:
		print("Impossible de capturer l'image de la galerie")
	quit(0)
