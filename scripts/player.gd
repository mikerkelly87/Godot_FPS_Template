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
var mouse_sensitivity := 0.001
var max_health := 100.0
var health := max_health

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


signal deal_damage(object)

func _ready():
	# Capture mouse for mouse look
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# Handle mouse look
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
		$Camera3D.rotation.x = clampf($Camera3D.rotation.x, -deg_to_rad(70), deg_to_rad(70))


func _physics_process(delta: float) -> void:
	update_stamina_bar()
	#raycast_debugging()
	shoot()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	# Handle sprint input.
	if can_sprint == true:
		if Input.is_action_just_pressed("sprint"):
			$SprintRecharge.stop()
			is_sprinting = true
			speed = sprint_speed
			stamina -= 10.0
			$SprintCooldown.start()
		elif Input.is_action_just_released("sprint"):
			is_sprinting = false
			speed = BASE_SPEED
			$SprintCooldown.stop()
			$SprintRecharge.start()
	elif can_sprint == false:
		if Input.is_action_pressed("sprint"):
			speed = BASE_SPEED
		if Input.is_action_just_released("sprint"):
			is_sprinting = false
			speed = BASE_SPEED
			$SprintCooldown.stop()
			$SprintRecharge.start()

	# Handle crouch
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
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()


func _on_sprint_cooldown_timeout() -> void:
	stamina -= 10.0
	if stamina < 0.0:
		stamina = 0.0
	if stamina <= 0.0:
		can_sprint = false
		$SprintCooldown.stop()


func _on_sprint_recharge_timeout() -> void:
	if stamina < max_stamina:
		stamina += 10.0
		can_sprint = true
		if stamina > max_stamina:
			stamina = max_stamina
			$SprintRecharge.stop()
		if stamina >= max_stamina:
			$SprintRecharge.stop()


func update_stamina_bar() -> void:
	$UI/Control/StaminaBar.value = stamina
	if stamina < max_stamina:
		$UI/Control/StaminaBar.visible = true
	if stamina >= max_stamina:
		$UI/Control/StaminaBar.visible = false


func raycast_debugging() -> void:
	if $Camera3D/RayCast3D.is_colliding() == true:
		print("Raycast is colliding with an area")
		var collided_object_id = $Camera3D/RayCast3D.get_collider_rid()
		var collided_object = $Camera3D/RayCast3D.get_collider()
		print(collided_object_id)
		print(collided_object)
	elif $Camera3D/RayCast3D.is_colliding() == false:
		print("Raycast is not colliding with an area")


func shoot() -> void:
	if Input.is_action_just_pressed("shoot"):
		if $Camera3D/RayCast3D.is_colliding() == true:
			var collided_object = $Camera3D/RayCast3D.get_collider()
			#print("You shot ", collided_object.name)
			deal_damage.emit(collided_object)
		elif $Camera3D/RayCast3D.is_colliding() == false:
			print("You missed")
