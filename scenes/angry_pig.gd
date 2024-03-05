extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D


const SPEED = 300.0
const WALK = 50.0

var is_going_to_right: bool = true
var is_running: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	
	# sprite animation of the character
	animate_character()
	# vitesse movement of the character on X and Y
	character_movement(delta)
	
	
func animate_character():
	
	#animate character on the floor
	if (velocity.x > 1 || velocity.x < -1):
		if is_running:
			animated_sprite_2d.animation = "running"
		else:
			animated_sprite_2d.animation = "walking"
	if velocity.x < 1 and velocity.x > -1: 
		animated_sprite_2d.animation = "default"
	
	# flip animation
	animated_sprite_2d.flip_h = is_going_to_right


func character_movement(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	
	var char_velocity = WALK
	if is_running:
		char_velocity = SPEED
	else:
		char_velocity = WALK
	
	if is_going_to_right:
		var direction = 1
		velocity.x = direction * char_velocity
	else:
		var direction = -1
		velocity.x = direction * char_velocity
	
	move_and_slide()
	
	if velocity.x < 1 and velocity.x > -1:
		is_going_to_right = !is_going_to_right


func running_mode(is_going_to_run:bool, is_player_area_right:bool):
	if is_going_to_run == true:
		if is_going_to_right == is_player_area_right:
			is_running = true
		else:
			is_running = false
	else:
		is_running = false
