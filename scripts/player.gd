extends CharacterBody2D

# General movement constants
const SPEED = 250.0
const JUMP_VELOCITY = -400.0
const COYOTE_TIME = 0.15
const JUMP_BUFFER = 0.15

# Wall interaction constants
const WALL_SLIDE_SPEED = 100.0
const MIN_WALL_JUMP_VELOCITY = 200
const MAX_WALL_JUMP_VELOCITY = 300
const WALL_JUMP_VELOCITY_CHANGE = 35
const WALL_JUMP_DURATION = 0.25
const LEDGE_GRAB_COOLDOWN = 0.1

# Dash constants
const DASH_SPEED = 750.0
const DASH_DURATION = 0.18
const DASH_COOLDOWN = 0.5

enum PlayerState {
	IDLE,
	RUNNING,
	DASHING,
	JUMPING,
	FALLING,
	WALL_SLIDING,
	WALL_JUMPING,
	LEDGE_GRABBING,
}

var state: PlayerState = PlayerState.IDLE
var prev_direction: float = 1
var direction: float = 0
var wall_jump_velocity: float = MIN_WALL_JUMP_VELOCITY

var can_dash: bool = true
var can_ledge_grab: bool = true

@onready var center: Marker2D = get_node("Marker2D")
@onready var top_cast: RayCast2D = get_node("Marker2D/TopRayCast")
@onready var bottom_cast: RayCast2D = get_node("Marker2D/BottomRayCast")

func _physics_process(delta: float) -> void:
	# Get movement input
	direction = Input.get_axis("Left", "Right")

	match state:
		PlayerState.WALL_JUMPING:
			velocity += get_gravity() * delta
			move_and_slide()
			return
		PlayerState.DASHING:
			velocity.x = DASH_SPEED * prev_direction
			velocity.y = 0
			move_and_slide()
			return
		PlayerState.WALL_SLIDING:
			velocity.y = WALL_SLIDE_SPEED
			if Input.is_action_just_pressed("Dash") and can_dash:
				prev_direction *= -1
				_dash()
			if wall_jump_velocity > MIN_WALL_JUMP_VELOCITY and Input.is_action_just_pressed("Jump"):
				_wall_jump()
			if is_on_floor() or center.scale.x != direction or !top_cast.is_colliding():
				state = PlayerState.IDLE
			move_and_slide()
			return
		PlayerState.LEDGE_GRABBING:
			if Input.is_action_just_pressed("Jump"):
				_ledge_grab_jump()
			return

	# Update prev_direction and player orientation (flips the marker left/right)
	if direction != 0:
		prev_direction = direction
		center.scale.x = direction
		
	# State logic for determining if wall slide/ledge grabbing
	if _determine_wall_state():
		return
	
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		wall_jump_velocity = MAX_WALL_JUMP_VELOCITY
	
	# Handle jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.3
	
	# Reset dash tag
	if !can_dash and is_on_floor():
		_reset_dash()
	
	# Handle the dash input
	if Input.is_action_just_pressed("Dash") and can_dash:
		_dash()
		return
	
	# Handle horizontal movement
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():
			state = PlayerState.RUNNING
	else:
		velocity.x = 0
		if velocity.y == 0:
			state = PlayerState.IDLE
		elif velocity.y < 0:
			state = PlayerState.FALLING

	move_and_slide()

# Handle state during dash
func _dash():
	state = PlayerState.DASHING
	can_dash = false
	
	await get_tree().create_timer(DASH_DURATION).timeout
	state = PlayerState.IDLE

# Reset dash without pausing main code
func _reset_dash():
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true

# Returns if player is able to ledge grab or wall slide
func _determine_wall_state() -> bool:
	if is_on_floor():
		return false
	
	if can_ledge_grab and !top_cast.is_colliding() and bottom_cast.is_colliding():
		state = PlayerState.LEDGE_GRABBING
		velocity = Vector2.ZERO
		return true
	
	if velocity.y > 0 and top_cast.is_colliding() and bottom_cast.is_colliding() and center.scale.x == direction:
		state = PlayerState.WALL_SLIDING
		return true
		
	return false

func _ledge_grab_jump():
	velocity.y = JUMP_VELOCITY
	state = PlayerState.JUMPING
	move_and_slide()
	
	can_ledge_grab = false
	await get_tree().create_timer(LEDGE_GRAB_COOLDOWN).timeout
	can_ledge_grab = true

func _wall_jump():
	velocity.y = -wall_jump_velocity
	velocity.x = -direction * wall_jump_velocity
	state = PlayerState.WALL_JUMPING
	
	await get_tree().create_timer(WALL_JUMP_DURATION).timeout

	state = PlayerState.IDLE
	wall_jump_velocity = clamp(wall_jump_velocity - WALL_JUMP_VELOCITY_CHANGE, MIN_WALL_JUMP_VELOCITY, MAX_WALL_JUMP_VELOCITY)
