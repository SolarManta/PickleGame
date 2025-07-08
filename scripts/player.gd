# Times are in seconds unless it says otherwise

extends CharacterBody2D

# General movement constants
const SPEED = 250.0
const JUMP_VELOCITY = -400.0
const JUMP_RELEASE_COEFF = 0.3 # The lower this is, the longer player stays in air after releasing jump early
const COYOTE_TIME = 5 # In frames
const JUMP_BUFFER = 0.04

# Wall interaction constants
const WALL_SLIDE_SPEED = 100.0
const MIN_WALL_JUMP_SPEED = 200
const MAX_WALL_JUMP_SPEED = 400
const WALL_JUMP_SPEED_CHANGE = 75
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
var wall_jump_speed: float = MIN_WALL_JUMP_SPEED
var coyote_time: int = 0

var can_dash: bool = true
var can_ledge_grab: bool = true
var buffered_jump: bool = false

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
			if wall_jump_speed > MIN_WALL_JUMP_SPEED and Input.is_action_just_pressed("Jump"):
				_wall_jump()
			if is_on_floor() or center.scale.x != direction or !top_cast.is_colliding():
				switch_state(PlayerState.IDLE)
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
		wall_jump_speed = MAX_WALL_JUMP_SPEED
	
	# Handle jump
	if Input.is_action_just_pressed("Jump"):
		_start_jump_buffer()
	if buffered_jump and (is_on_floor() or coyote_time > 0):
		switch_state(PlayerState.JUMPING)
		velocity.y = JUMP_VELOCITY
		buffered_jump = false
		coyote_time = 0
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= JUMP_RELEASE_COEFF
	
	# Update coyote time
	if is_on_floor():
		coyote_time = COYOTE_TIME
	elif coyote_time > 0:
		coyote_time -= 1
	
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
			switch_state(PlayerState.RUNNING)
	else:
		velocity.x = 0
		if velocity.y == 0:
			switch_state(PlayerState.IDLE)
		elif velocity.y > 0:
			switch_state(PlayerState.FALLING)

	move_and_slide()

func switch_state(new_state: PlayerState):
	if state == new_state:
		return
	
	#print("State switched from " + PlayerState.keys()[state] + " to " + PlayerState.keys()[new_state])
	state = new_state
	match state:
		PlayerState.LEDGE_GRABBING:
			can_dash = true
			
			if bottom_cast.is_colliding() and bottom_cast.get_collider() is TileMapLayer:
				var tilemap = bottom_cast.get_collider() as TileMapLayer
				var collision_point = bottom_cast.get_collision_point()
				var tile_coords = tilemap.local_to_map(collision_point)
				var tile_pos = tilemap.map_to_local(tile_coords)
				
				if prev_direction == -1:
					position = tile_pos - Vector2(1, 10)
				elif prev_direction == 1:
					position = tile_pos - Vector2(31, 10)

# Handle state during dash
func _dash():
	switch_state(PlayerState.DASHING)
	can_dash = false
	
	await get_tree().create_timer(DASH_DURATION).timeout
	switch_state(PlayerState.IDLE)

# Reset dash without pausing main code
func _reset_dash():
	await get_tree().create_timer(DASH_COOLDOWN).timeout
	can_dash = true

# Returns if player is able to ledge grab or wall slide
func _determine_wall_state() -> bool:
	if is_on_floor():
		return false
	
	if can_ledge_grab and !top_cast.is_colliding() and bottom_cast.is_colliding():
		switch_state(PlayerState.LEDGE_GRABBING)
		velocity = Vector2.ZERO
		return true
	
	if velocity.y > 0 and top_cast.is_colliding() and bottom_cast.is_colliding() and center.scale.x == direction:
		switch_state(PlayerState.WALL_SLIDING)
		return true
		
	return false

func _ledge_grab_jump():
	switch_state(PlayerState.JUMPING)
	velocity.y = JUMP_VELOCITY
	move_and_slide()
	
	can_ledge_grab = false
	await get_tree().create_timer(LEDGE_GRAB_COOLDOWN).timeout
	can_ledge_grab = true

func _wall_jump():
	switch_state(PlayerState.WALL_JUMPING)
	velocity.y = -wall_jump_speed
	velocity.x = -prev_direction * wall_jump_speed
	
	await get_tree().create_timer(WALL_JUMP_DURATION).timeout
	switch_state(PlayerState.FALLING)
	wall_jump_speed = clamp(wall_jump_speed - WALL_JUMP_SPEED_CHANGE, MIN_WALL_JUMP_SPEED, MAX_WALL_JUMP_SPEED)

func _start_jump_buffer():
	buffered_jump = true
	await get_tree().create_timer(JUMP_BUFFER).timeout
	buffered_jump = false
