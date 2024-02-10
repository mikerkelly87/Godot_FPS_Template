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
var current_weapon := "" # choices: BlueGun, RedGun

# For debugging
var inventory_was_printed = false


# Inventory dictionary variable
var inventory := {
	"BlueGun": {"in_inventory": false, "is_equipped": false, "image": preload("res://assets/BlueGunUnselected.png"), "ammo": 0},
	"RedGun": {"in_inventory": false, "is_equipped": false, "image": preload("res://assets/RedGunUnselected.png"), "ammo": 0},
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


signal deal_damage(object)
signal item_collection_collide(object)
signal picked_up_item(object)
signal dropped_item(object)


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
	weapon_select()
	item_pickup()
	show_weapons()
	ammo_counter()
	drop_weapon()
	
		
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
	if $Camera3D/WeaponRayCast.is_colliding() == true:
		print("Raycast is colliding with an area")
		var collided_object_id = $Camera3D/WeaponRayCast.get_collider_rid()
		var collided_object = $Camera3D/WeaponRayCast.get_collider()
		print(collided_object_id)
		print(collided_object)
		print(collided_object.name)
	elif $Camera3D/WeaponRayCast.is_colliding() == false:
		pass
		#print("Raycast is not colliding with an area")


# Function to handle weapon selection. All weapons are attached to the weapon node
# and are not visible by default unless they are set as the current_weapon.
func weapon_select():
	# Handle selecting the first weapon pickup
	if current_weapon == "":
		if inventory["BlueGun"].in_inventory == false:
			if inventory["RedGun"].in_inventory == false:
				$UI/Control/AmmoCount.visible = false
		if inventory["BlueGun"].in_inventory == true:
			current_weapon = "BlueGun"
			inventory["BlueGun"].is_equipped = true
			$UI/Control/AmmoCount.visible = true
		if inventory["RedGun"].in_inventory == true:
			current_weapon = "RedGun"
			inventory["RedGun"].is_equipped = true
			$UI/Control/AmmoCount.visible = true
	# Handle weapon selection with number keys
	if inventory["BlueGun"].in_inventory == true:
		if Input.is_action_just_pressed("select_weapon_1"):
			current_weapon = "BlueGun"
			inventory["BlueGun"].is_equipped = true
			inventory["RedGun"].is_equipped = false
	if inventory["RedGun"].in_inventory == true:
		if Input.is_action_just_pressed("select_weapon_2"):
			current_weapon = "RedGun"
			inventory["RedGun"].is_equipped = true
			inventory["BlueGun"].is_equipped = false

	# Handle weapon selection with mouse scroll wheel
	if Input.is_action_just_pressed("select_weapon_scroll_up"):
		if current_weapon == "BlueGun":
			if inventory["RedGun"].in_inventory == true:
				current_weapon = "RedGun"
				inventory["RedGun"].is_equipped = true
				inventory["BlueGun"].is_equipped = false
		elif current_weapon == "RedGun":
			if inventory["BlueGun"].in_inventory == true:
				current_weapon = "BlueGun"
				inventory["BlueGun"].is_equipped = true
				inventory["RedGun"].is_equipped = false
	if Input.is_action_just_pressed("select_weapon_scroll_down"):
		if current_weapon == "BlueGun":
			if inventory["RedGun"].in_inventory == true:
				current_weapon = "RedGun"
				inventory["RedGun"].is_equipped = true
				inventory["BlueGun"].is_equipped = false
		elif current_weapon == "RedGun":
			if inventory["BlueGun"].in_inventory == true:
				current_weapon = "BlueGun"
				inventory["BlueGun"].is_equipped = true
				inventory["RedGun"].is_equipped = false
	# Make the current weapon visible
	if current_weapon == "RedGun":
		$Camera3D/Weapon/RedGun.visible = true
		$Camera3D/Weapon/BlueGun.visible = false
	if current_weapon == "BlueGun":
		$Camera3D/Weapon/RedGun.visible = false
		$Camera3D/Weapon/BlueGun.visible = true
	if current_weapon == "":
		$Camera3D/Weapon/RedGun.visible = false
		$Camera3D/Weapon/BlueGun.visible = false

# Function to shoot enemies. If the player shoots while the ray cast connects
# with an enemy Area3D hitbox, then emit the deal_damage signal, passing the 
# ID of the object that was shot.
func shoot() -> void:
	if Input.is_action_just_pressed("shoot"):
		if can_shoot == true:
			if current_weapon == "RedGun":
				$Camera3D/Weapon/RedGun/AnimationPlayer.play("fire")
				inventory["RedGun"].ammo -= 1
			if current_weapon == "BlueGun":
				$Camera3D/Weapon/BlueGun/AnimationPlayer.play("fire")
				inventory["BlueGun"].ammo -= 1
			if $Camera3D/WeaponRayCast.is_colliding() == true:
				var collided_object_id = $Camera3D/WeaponRayCast.get_collider_rid()
				deal_damage.emit(collided_object_id)
				$UI/Control/CenterContainer/CrosshairMain.visible = false
				$UI/Control/CenterContainer/CrosshairHit.visible = true
				$UI/CrosshairTimer.start()
			elif $Camera3D/WeaponRayCast.is_colliding() == false:
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


# Handle item pickups
func item_pickup() -> void:
	var collided_object_id = $Camera3D/ItemRayCast.get_collider_rid()
	if $Camera3D/ItemRayCast.is_colliding() == true:
		item_collection_collide.emit(collided_object_id)
	elif $Camera3D/ItemRayCast.is_colliding() == false:
		$UI/Control/message_text.text = ""


# Display the weapons in the weapon select images at the top of the screen
func show_weapons():
	if inventory["BlueGun"].in_inventory == true:
		$UI/Control/WeaponSelect/HBoxContainer/BlueGun.visible = true
	elif inventory["BlueGun"].in_inventory == false:
		$UI/Control/WeaponSelect/HBoxContainer/BlueGun.visible = false
	if inventory["RedGun"].in_inventory == true:
		$UI/Control/WeaponSelect/HBoxContainer/RedGun.visible = true
	elif inventory["RedGun"].in_inventory == false:
		$UI/Control/WeaponSelect/HBoxContainer/RedGun.visible = false
	if inventory["BlueGun"].is_equipped == true:
		$UI/Control/WeaponSelect/HBoxContainer/BlueGun.texture = preload("res://assets/BlueGunSelected.png")
		if inventory["RedGun"].in_inventory == true:
			$UI/Control/WeaponSelect/HBoxContainer/RedGun.texture = preload("res://assets/RedGunUnselected.png")
		if inventory["RedGun"].in_inventory == false:
			$UI/Control/WeaponSelect/HBoxContainer/RedGun.visible = false
	if inventory["RedGun"].is_equipped == true:
		$UI/Control/WeaponSelect/HBoxContainer/RedGun.texture = preload("res://assets/RedGunSelected.png")
		if inventory["BlueGun"].in_inventory == true:
			$UI/Control/WeaponSelect/HBoxContainer/BlueGun.texture = preload("res://assets/BlueGunUnselected.png")
		if inventory["BlueGun"].in_inventory == false:
			$UI/Control/WeaponSelect/HBoxContainer/BlueGun.visible = false


# Pick up blue gun
func _on_pickup_blue_gun_display_message(message):
	$UI/Control/message_text.text = message
	if Input.is_action_just_pressed("pickup_item"):
		inventory["BlueGun"].in_inventory = true
		inventory["BlueGun"].ammo += 10
		$UI/Control/message_text.text = ""
		picked_up_item.emit("BlueGun")


# Pick up red gun
func _on_pickup_red_gun_display_message(message: Variant) -> void:
	$UI/Control/message_text.text = message
	if Input.is_action_just_pressed("pickup_item"):
		inventory["RedGun"].in_inventory = true
		inventory["RedGun"].ammo += 10
		$UI/Control/message_text.text = ""
		picked_up_item.emit("RedGun")


func drop_weapon():
	if Input.is_action_just_pressed("drop_weapon"):
		if current_weapon != "":
			dropped_item.emit(current_weapon)
			inventory[current_weapon].is_equipped = false
			inventory[current_weapon].in_inventory = false
			inventory[current_weapon].ammo = 0
			if current_weapon == "BlueGun":
				if inventory["RedGun"].in_inventory == true:
					current_weapon = "RedGun"
					inventory["RedGun"].is_equipped = true
				else:
					current_weapon = ""
			if current_weapon == "RedGun":
				if inventory["BlueGun"].in_inventory == true:
					current_weapon = "BlueGun"
					inventory["BlueGun"].is_equipped = true
				else:
					current_weapon = ""


# Handle ammo counter
func ammo_counter():
	if current_weapon == "BlueGun":
		var blue_ammo = inventory["BlueGun"].ammo
		$UI/Control/AmmoCount/HBoxContainer/Label2.text = str(blue_ammo)
		if inventory["BlueGun"].ammo == 0:
			can_shoot = false
		elif inventory["BlueGun"].ammo > 0:
			can_shoot = true
	if current_weapon == "RedGun":
		var red_ammo = inventory["RedGun"].ammo
		$UI/Control/AmmoCount/HBoxContainer/Label2.text = str(red_ammo)
		if inventory["RedGun"].ammo == 0:
			can_shoot = false
		elif inventory["RedGun"].ammo > 0:
			can_shoot = true
	#if current_weapon == "RedGun":
