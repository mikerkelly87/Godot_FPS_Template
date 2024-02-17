extends Node3D

var respawn := true
var ammo_count := 10

signal display_message(message, ammo)
signal stop_message()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


# Make any instance on the floor disappear after 3 seconds
func gun_disappear():
	if self.position.y == 0:
		print("Disappear timer started")
		$DisappearTimer.start()


func _on_area_3d_body_entered(body):
	display_message.emit("Press E to pick up Blue Gun")


func _on_area_3d_body_exited(body):
	stop_message.emit()


func _on_player_item_collection_collide(object: Variant) -> void:
	var my_pickup_range_rid = $Cube/PickupRange.get_rid()
	if str(object) == str(my_pickup_range_rid):
		display_message.emit("Press E to pick up Blue Gun", ammo_count, self.position.y)
		#print("Press E to pick up Blue Gun")


func _on_player_picked_up_item(object, location):
	# If the gun is not on the ground, respawn it
	if self.position.y != 0:
		if object == "BlueGun" && location == "table":
			self.visible = false
			$Cube/PickupRange/CollisionShape3D.disabled = true
			$RespawnTimer.start()
	# If the gun is on the ground, don't respawn it
	elif self.position.y == 0:
		if object == "BlueGun" && location == "ground":
			self.visible = false
			$Cube/PickupRange/CollisionShape3D.disabled = true


func _on_respawn_timer_timeout() -> void:
	self.visible = true
	$Cube/PickupRange/CollisionShape3D.disabled = false


# This function will be called from the Main scene when the player drops the gun
func initialize(player_position, player, current_ammo):
	#respawn = false
	rotate_z(80)
	position.x = player_position.x
	position.z = player_position.z
	position.y = 0
	var player_node = player
	player.item_collection_collide.connect(_on_player_item_collection_collide)
	player.picked_up_item.connect(_on_player_picked_up_item)
	ammo_count = current_ammo
	gun_disappear()


func _on_disappear_timer_timeout():
	print("Disappear timer timed out")
	self.visible = false
	$Cube/PickupRange/CollisionShape3D.disabled = true
