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
