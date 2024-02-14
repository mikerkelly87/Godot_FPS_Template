extends Node3D


@export var blue_gun_scene: PackedScene
@export var red_gun_scene: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_dropped_item(object, ammo):
	# Create a new instance of the dropped item's scene.
	var current_ammo = ammo
	var item_scene
	if object == "BlueGun":
		item_scene = blue_gun_scene.instantiate()
		# Run the connect_signals function in the player script to connect signals
		# from the dropped item
		$Player.connect_signals(item_scene)
	if object == "RedGun":
		item_scene = red_gun_scene.instantiate()
		# Run the connect_signals function in the player script to connect signals
		# from the dropped item
		$Player.connect_signals(item_scene)

	var player_position = $Player.position
	var player = $Player
	
	# Run the initialize function in the item script to set the position and
	# connect signals from the player scene
	item_scene.initialize(player_position, player, current_ammo)

	# Spawn the dropped item.
	add_child(item_scene)
