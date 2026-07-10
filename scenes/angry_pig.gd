extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D

const RUNNING = 300.0
const WALK = 50.0
# Ignore tiny left/right differences to avoid jitter when player is almost aligned.
const TURN_DEADZONE_X = 12.0
# Minimum delay between two direction flips for smoother tracking behavior.
const TURN_COOLDOWN_SECONDS = 0.5
var health := 5
var player: CharacterBody2D
var character_velocity = WALK

var is_hit: bool = false
var hit_animation: String = "hit1"
const DAMAGE_COOLDOWN_SECONDS = 0.25
@onready var damage_cooldown_timer: Timer = $DamageCooldownTimer

var is_going_to_right: bool = false
var is_running: bool = false
var turn_cooldown_left := 0.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	damage_cooldown_timer.one_shot = true
	damage_cooldown_timer.wait_time = DAMAGE_COOLDOWN_SECONDS
	damage_cooldown_timer.timeout.connect(_on_damage_cooldown_timer_timeout)


func _physics_process(delta):
	# sprite animation of the character
	animate_character()
	# vitesse movement of the character on X and Y
	character_movement(delta)
	
func animate_character():
	#animate character on the floor
	if (velocity.x > 1 || velocity.x < -1):
		if is_hit:
			animated_sprite_2d.animation = hit_animation
		elif is_running:
			animated_sprite_2d.animation = "running"
		else:
			animated_sprite_2d.animation = "walking"
	else: 
		animated_sprite_2d.animation = "default"
	
	# be sure to play animation
	animated_sprite_2d.play()
	
	# flip animation
	animated_sprite_2d.flip_h = is_going_to_right

func character_movement(delta):
	# Countdown that throttles how often the pig is allowed to turn around.
	if turn_cooldown_left > 0.0:
		turn_cooldown_left = max(0.0, turn_cooldown_left - delta)
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if player:
		character_velocity = RUNNING
		is_running = true
		var dir = player.position.x - position.x
		# Turn only when player is clearly on one side and cooldown is finished.
		if absf(dir) > TURN_DEADZONE_X and turn_cooldown_left <= 0.0:
			var should_go_right = dir > 0
			if should_go_right != is_going_to_right:
				is_going_to_right = should_go_right
				# Start cooldown to prevent rapid flip-flop at the boundary.
				turn_cooldown_left = TURN_COOLDOWN_SECONDS
	else:
		character_velocity = WALK
		is_running = false
	
	if is_going_to_right:
		var direction = 1
		velocity.x = direction * character_velocity
	else:
		var direction = -1
		velocity.x = direction * character_velocity
	
	move_and_slide()
	
	if velocity.x < 1 and velocity.x > -1:
		is_going_to_right = !is_going_to_right
	
	

func _on_enemi_area_body_entered(player_body: CharacterBody2D) -> void:
	player = player_body

func _on_enemi_area_body_exited(_player_body: CharacterBody2D) -> void:
	player = null

func get_damage():
	if not damage_cooldown_timer.is_stopped():
		return

	print("damage angry_pig")
	is_hit = true
	hit_animation = ["hit1", "hit2"].pick_random()
	health -= 1
	damage_cooldown_timer.start()
	if health <= 0:
		queue_free()
	
func _on_damage_cooldown_timer_timeout():
	if is_hit:
		is_hit = false
