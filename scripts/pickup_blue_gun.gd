extends Node3D

signal display_message(message)
signal stop_message()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	display_message.emit("Press E to pick up Blue Gun")


func _on_area_3d_body_exited(body):
	stop_message.emit()


func _on_player_item_collection_collide(object: Variant) -> void:
	var my_pickup_range_rid = $Cube/PickupRange.get_rid()
	if str(object) == str(my_pickup_range_rid):
		display_message.emit("Press E to pick up Blue Gun")
		#print("Press E to pick up Blue Gun")


func _on_player_picked_up_item(object: Variant) -> void:
	if object == "BlueGun":
		self.visible = false
		$Cube/PickupRange/CollisionShape3D.disabled = true
		$RespawnTimer.start()


func _on_respawn_timer_timeout() -> void:
	self.visible = true
	$Cube/PickupRange/CollisionShape3D.disabled = false

# This function will be called from the Main scene when the player drops the gun
func initialize(player_position, player):
	rotate_z(80)
	position.x = player_position.x
	position.z = player_position.z
	position.y = 0
	var player_node = player
	player.item_collection_collide.connect(_on_player_item_collection_collide)
	player.picked_up_item.connect(_on_player_picked_up_item)
