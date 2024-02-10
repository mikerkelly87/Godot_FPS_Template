extends Node3D

signal display_message(message)
signal stop_message()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_pickup_range_body_entered(body: Node3D) -> void:
	display_message.emit("Press E to pick up Red Gun")


func _on_pickup_range_body_exited(body: Node3D) -> void:
	stop_message.emit()


func _on_player_item_collection_collide(object: Variant) -> void:
	var my_pickup_range_rid = $Cube/PickupRange.get_rid()
	if str(object) == str(my_pickup_range_rid):
		display_message.emit("Press E to pick up Red Gun")
		#print("Press E to pick up Blue Gun")


func _on_player_picked_up_item(object: Variant) -> void:
	if object == "RedGun":
		self.visible = false
		$Cube/PickupRange/CollisionShape3D.disabled = true
		$RespawnTimer.start()


func _on_respawn_timer_timeout() -> void:
	self.visible = true
	$Cube/PickupRange/CollisionShape3D.disabled = false
