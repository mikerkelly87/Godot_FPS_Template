extends CharacterBody3D

const BASE_SPEED := 5.0
var jump_velocity := 7.0
var speed := BASE_SPEED
var sprint_speed := 20.0
var max_stamina := 50.0
var stamina := max_stamina
var crouch_speed := 2.0
var can_sprint := true
var is_sprinting := false
var can_shoot := true
#var mouse_sensitivity := 0.001
var max_health := 100.0
var health := max_health
var game_paused = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


signal deal_damage(object)

func _ready():
	# Capture mouse for mouse look
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# This is only here because at this time I can't figure out why the m1911
	# instance starts itself off at the middle keyframe of the fire animation
	#$Camera3D/m1911/AnimationPlayer.play("fire")


# Handle mouse look
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * GameVars.mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * GameVars.mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))


func _physics_process(delta: float) -> void:
	update_stamina_bar()
	#raycast_debugging()
	shoot()
	pause_menu()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle sprint input.
	if can_sprint == true:
		if Input.is_action_just_pressed("sprint"):
			$Camera3D/AnimationPlayer.play("sprint")
			#$Camera3D/m1911/AnimationPlayer.play("lower")
			$SprintRecharge.stop()
			is_sprinting = true
			can_shoot = false
			speed = sprint_speed
			stamina -= 10.0
			$SprintCooldown.start()
		elif Input.is_action_just_released("sprint"):
			$Camera3D/AnimationPlayer.stop()
			#$Camera3D/m1911/AnimationPlayer.play("raise")
			is_sprinting = false
			can_shoot = true
			speed = BASE_SPEED
			$SprintCooldown.stop()
			$SprintRecharge.start()
	elif can_sprint == false:
		if Input.is_action_pressed("sprint"):
			$Camera3D/AnimationPlayer.play("walk")
			#$Camera3D/m1911/AnimationPlayer.play("raise")
			can_shoot = true
			speed = BASE_SPEED
		if Input.is_action_just_released("sprint"):
			$Camera3D/AnimationPlayer.stop()
			#$Camera3D/m1911/AnimationPlayer.play("raise")
			is_sprinting = false
			can_shoot = true
			speed = BASE_SPEED
			$SprintCooldown.stop()
			$SprintRecharge.start()

	# Handle crouch by lowering camera position
	if Input.is_action_pressed("crouch"):
		can_sprint = false
		$Camera3D.position.y = 0.0
		speed = crouch_speed
	elif Input.is_action_just_released("crouch"):
		$Camera3D.position.y = 0.5
		speed = BASE_SPEED
		can_sprint = true
		
	# Set value of health bar
	$UI/Control/HealthBar.value = health

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		$Camera3D/AnimationPlayer.play("walk")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		$Camera3D/AnimationPlayer.stop()
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


# Every second while sprinting, remove 10 stamina
# Make the player unable to sprint if the stamina is 0
func _on_sprint_cooldown_timeout() -> void:
	stamina -= 10.0
	if stamina < 0.0:
		stamina = 0.0
	if stamina <= 0.0:
		can_sprint = false
		$SprintCooldown.stop()


# When the player stops sprinting, add 10 stamina every second
# until the stamina is full
func _on_sprint_recharge_timeout() -> void:
	if stamina < max_stamina:
		stamina += 10.0
		can_sprint = true
		if stamina > max_stamina:
			stamina = max_stamina
			$SprintRecharge.stop()
		if stamina >= max_stamina:
			$SprintRecharge.stop()


# Update the stamina progress bar with the value of the player's stamina
# Only show the stamina bar if the player's stamina is not full
func update_stamina_bar() -> void:
	$UI/Control/StaminaBar.value = stamina
	if stamina < max_stamina:
		$UI/Control/StaminaBar.visible = true
	if stamina >= max_stamina:
		$UI/Control/StaminaBar.visible = false


# Debugging funciton for testing ray casting
func raycast_debugging() -> void:
	if $Camera3D/RayCast3D.is_colliding() == true:
		print("Raycast is colliding with an area")
		var collided_object_id = $Camera3D/RayCast3D.get_collider_rid()
		var collided_object = $Camera3D/RayCast3D.get_collider()
		print(collided_object_id)
		print(collided_object)
		print(collided_object.name)
	elif $Camera3D/RayCast3D.is_colliding() == false:
		pass
		#print("Raycast is not colliding with an area")


# Function to shoot enemies. If the player shoots while the ray cast connects
# with an enemy Area3D hitbox, then emit the deal_damage signal, passing the 
# ID of the object that was shot.
func shoot() -> void:
	if Input.is_action_just_pressed("shoot"):
		if can_shoot == true:
			$Camera3D/m1911/AnimationPlayer.play("fire")
			if $Camera3D/RayCast3D.is_colliding() == true:
				var collided_object_id = $Camera3D/RayCast3D.get_collider_rid()
				deal_damage.emit(collided_object_id)
				$UI/Control/CenterContainer/CrosshairMain.visible = false
				$UI/Control/CenterContainer/CrosshairHit.visible = true
				$UI/CrosshairTimer.start()
			elif $Camera3D/RayCast3D.is_colliding() == false:
				pass


# Set the player's crosshair back to normal after landing a hit.
func _on_crosshair_timer_timeout():
	$UI/Control/CenterContainer/CrosshairMain.visible = true
	$UI/Control/CenterContainer/CrosshairHit.visible = false


# Access Pause menu
func pause_menu():
	if Input.is_action_just_pressed("pause"):
		if game_paused == false:
			$UI/Control.visible = false
			$PauseMenu/PauseControl.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			game_paused = true
		elif game_paused == true:
			$UI/Control.visible = true
			$PauseMenu/PauseControl.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			game_paused = false


# Exit pause menu
func _on_pause_menu_exit_pause_menu():
	$PauseMenu/PauseControl.visible = false
	$UI/Control.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_paused = false
