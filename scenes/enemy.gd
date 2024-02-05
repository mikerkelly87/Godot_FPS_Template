extends CharacterBody3D

var max_health := 20.0
var health := max_health



func _on_player_deal_damage(object: Variant) -> void:
	var my_hitbox_rid = $Hitbox.get_rid()
	var my_rid = get_rid()
	#print("Printing the object from the enemy script as ", object)
	#print("This enemy's Area3D RID is ", my_hitbox_rid)
	#print("This enemy's RID is ", my_rid)
	
	if str(object.name) == $Hitbox.name:
		print("The enemy says you shot me, partner")
		health -= 5
		print("This enemy's health is ", health)
