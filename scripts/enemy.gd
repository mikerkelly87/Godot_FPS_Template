extends CharacterBody3D

var max_health := 20.0
var health := max_health


func _physics_process(delta: float) -> void:
	enemy_death()


# Kill the enemy if their health is 0
func enemy_death():
	if health < 0:
		health = 0
	if health == 0:
		queue_free()


# Take damage from the deal_damage signal from the player
func _on_player_deal_damage(object: Variant) -> void:
	var my_hitbox_rid = $Hitbox.get_rid()
	var my_rid = get_rid()
	if str(object) == str(my_hitbox_rid):
		print("The enemy says you shot me, partner")
		health -= 5
		print("This enemy's health is ", health)
