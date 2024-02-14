extends Node3D

var respawn := true
var ammo_count := 10

signal display_message(message, ammo)
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
		display_message.emit("Press E to pick up Red Gun", ammo_count)
		#print("Press E to pick up Blue Gun")


func _on_player_picked_up_item(object: Variant) -> void:
	if object == "RedGun":
		self.visible = false
		$Cube/PickupRange/CollisionShape3D.disabled = true
		if respawn == true:
			$RespawnTimer.start()


func _on_respawn_timer_timeout() -> void:
	self.visible = true
	$Cube/PickupRange/CollisionShape3D.disabled = false


# This function will be called from the Main scene when the player drops the gun
func initialize(player_position, player, current_ammo):
	respawn = false
	rotate_z(80)
	position.x = player_position.x
	position.z = player_position.z
	position.y = 0
	var player_node = player
	player.item_collection_collide.connect(_on_player_item_collection_collide)
	player.picked_up_item.connect(_on_player_picked_up_item)
	ammo_count = current_ammo
