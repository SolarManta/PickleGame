extends CharacterBody2D

const SPEED = 250.0
const DASH_SPEED = 750.0
const DASH_DURATION = 0.18
const DASH_COOLDOWN = 0.05
const JUMP_VELOCITY = -400.0

enum PlayerState {
	Idle,
	Running,
	Dashing,
	WallSliding,
	WallJumping,
}

var state: PlayerState = PlayerState.Idle
var prevDirection: float = 1

var canDash: bool = true

var center: Marker2D
var sprite: Sprite2D

func _ready() -> void:
	sprite = get_node("Sprite2D")
	center = get_node("Marker2D")

func _physics_process(delta: float) -> void:
	# Handle movement during dash
	if state == PlayerState.Dashing:
		velocity.x = DASH_SPEED * prevDirection
		velocity.y = 0
		move_and_slide()
		return
	
	# Get movement input
	var direction := Input.get_axis("Left", "Right")
	if direction != 0:
		prevDirection = direction
		center.scale.x = direction
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.3
	
	# Reset dash tag
	if !canDash and is_on_floor():
		_reset_dash()
	
	# Handle the dash input
	if Input.is_action_just_pressed("Dash") and canDash:
		_dash()
		return

	# Handle the movement/deceleration.
	if direction:
		state = PlayerState.Running
		velocity.x = direction * SPEED
	else:
		state = PlayerState.Idle
		velocity.x = 0

	move_and_slide()

# Handle state during dash
func _dash():
	state = PlayerState.Dashing
	canDash = false
	await get_tree().create_timer(DASH_DURATION).timeout
	state = PlayerState.Idle
	
func _reset_dash():
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	canDash = true
