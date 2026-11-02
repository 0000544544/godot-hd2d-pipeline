extends CharacterBody3D

@export var distance_patrouille : float = 4.0
@export var vitesse : float = 2.0

@onready var sprite : AnimatedSprite3D = get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D

var point_depart : Vector3
var point_arrivee : Vector3
var cible : Vector3

func _ready() -> void:
	point_depart = global_position
	point_arrivee = global_position + Vector3(distance_patrouille, 0.0, 0.0)
	cible = point_arrivee

	if sprite:
		if sprite.sprite_frames:
			if sprite.sprite_frames.has_animation("walk"):
				sprite.play("walk")
			elif sprite.sprite_frames.has_animation("default"):
				sprite.play("default")

	var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		for anim_name in ["Walking_A", "Walking_B", "Walking_C", "Running_A", "walk"]:
			if anim_player.has_animation(anim_name):
				var anim: Animation = anim_player.get_animation(anim_name)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
				anim_player.play(anim_name)
				break

func _physics_process(_delta: float) -> void:
	var direction := (cible - global_position).normalized()
	velocity = direction * vitesse
	move_and_slide()

	# Orientation du sprite selon la direction
	if sprite and abs(direction.x) > 0.1:
		sprite.flip_h = (direction.x < 0.0)
	elif has_node("Sprite3D") and abs(direction.x) > 0.1:
		var s3d = get_node("Sprite3D")
		if s3d and "flip_h" in s3d:
			s3d.flip_h = (direction.x < 0.0)
	elif has_node("ModelRoot") and abs(direction.x) > 0.1:
		var model = get_node("ModelRoot")
		model.rotation.y = -PI * 0.5 if direction.x < 0.0 else PI * 0.5

	# Inversion de la trajectoire à l'arrivée
	if global_position.distance_to(cible) < 0.2:
		cible = point_depart if cible == point_arrivee else point_arrivee
