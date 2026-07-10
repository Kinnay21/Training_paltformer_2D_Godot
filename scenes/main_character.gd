extends CharacterBody2D


const RUNNING = 400.0
const JUMP_VELOCITY = -800.0
const DAMAGE_BOUNCE = 900.0

const ACC = 50
const FRICTION = 70

const WALL_JUMP_PUSHBACK = 500
const WALL_SLIDE_GRAVITY = 100


var is_wall_slinding: bool = false
var is_going_to_left: bool = false
var can_double_jump: bool = true
var health := 5

@onready var sprite_2d = $Sprite2D

var is_invulnerable: bool = false
var is_hit: bool = false
const DAMAGE_COOLDOWN_SECONDS = 0.3
@onready var damage_cooldown_timer: Timer = $DamageCooldownTimer


var chosen_character = 1
var format_string_sprite_name = "%s_%s"

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready():
	damage_cooldown_timer.one_shot = true
	damage_cooldown_timer.wait_time = DAMAGE_COOLDOWN_SECONDS
	damage_cooldown_timer.timeout.connect(_on_damage_cooldown_timer_timeout)

func _physics_process(delta):
	# change character
	choose_character()
	# vitesse movement of the character on X and Y
	character_movement(delta)
	# sprite animation of the character
	animate_character()
	# wall slide behavior of the character
	wall_slide(delta)
	# jump action of the character
	jump()

func animate_character():
	if is_hit:
		sprite_2d.animation = format_string_sprite_name % ["hit", chosen_character]
	elif is_on_floor():
		#animate character on the floor
		if (velocity.x > 1 || velocity.x < -1):
			sprite_2d.animation = format_string_sprite_name % ["running",chosen_character]
			can_double_jump = true
		if velocity.x < 1 and velocity.x > -1: 
#			sprite_2d.animation = "default"
			sprite_2d.animation = format_string_sprite_name % ["default",chosen_character]
			can_double_jump = true
	else:
	# animate character in the air.
		if is_on_wall():
			sprite_2d.animation = format_string_sprite_name % ["wall_jump",chosen_character]
		else:
			if velocity.y < 0:
				if can_double_jump:
					sprite_2d.animation = format_string_sprite_name % ["jumping",chosen_character]
				else:
					sprite_2d.animation = format_string_sprite_name % ["double_jump",chosen_character]
			else:
				sprite_2d.animation = format_string_sprite_name % ["falling",chosen_character]
					
	sprite_2d.flip_h = is_going_to_left

func character_movement(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
			
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("left", "right")
	if direction:
#		velocity.x = direction * RUNNING
		velocity.x = move_toward(velocity.x, direction * RUNNING, ACC)
		if direction == 1:
			is_going_to_left = false
		else:
			is_going_to_left = true
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)
		
	move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is Node and collider.is_in_group("Ennemi"):
			#velocity += 50 * collision.get_normal()
			damage(collision, collider)

func wall_slide(delta):
	# slide on wall
	if is_on_wall() and !is_on_floor():
		if Input.is_action_pressed("right") or Input.is_action_pressed("left"):
			is_wall_slinding = true
		else:
			is_wall_slinding = false
	else:
		is_wall_slinding = false
	if is_wall_slinding:
		velocity.y += WALL_SLIDE_GRAVITY * delta
		velocity.y = min(velocity.y, WALL_SLIDE_GRAVITY)

func jump():
	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
		else:
			if is_on_wall() and Input.is_action_pressed("right"):
				velocity.y = JUMP_VELOCITY
				velocity.x = - WALL_JUMP_PUSHBACK
			if is_on_wall() and Input.is_action_pressed("left"):
				velocity.y = JUMP_VELOCITY
				velocity.x = WALL_JUMP_PUSHBACK
			if can_double_jump:
				velocity.y = JUMP_VELOCITY
				can_double_jump = false

func choose_character():
	if Input.is_action_just_pressed("pad_number_1"):
		chosen_character = 1
	if Input.is_action_just_pressed("pad_number_2"):
		chosen_character = 2
	if Input.is_action_just_pressed("pad_number_3"):
		chosen_character = 3
	if Input.is_action_just_pressed("pad_number_4"):
		chosen_character = 4

func damage(collision:KinematicCollision2D, enemy:Object):
	
	if is_invulnerable:
		return
	
	var collision_vector: Vector2 = collision.get_normal()

	if collision_vector.y < -0.7:
		# damage to ennemi and jump on it
		enemy.get_damage()
	else:
		# damage to player and bounce back
		health -= 1
		is_hit = true
		print("player life:", health)
		if health <= 0:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			
	is_invulnerable = true
	damage_cooldown_timer.start()
	velocity = collision_vector * DAMAGE_BOUNCE


func _on_damage_cooldown_timer_timeout():
	is_invulnerable = false
	if is_hit:
		is_hit = false
