extends CharacterBody3D

var max_health := 20.0
var health := max_health
var speed := 200
var target = null
var chase_player := false
var can_deal_damage := true
var doing_damage := false
var damage := 10


signal deal_damage(damage_amount)


func _physics_process(delta: float) -> void:
	enemy_death()
	follow_player()
	damage_to_player()


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


# When the player enters the range of the enemy, follow the player
func _on_player_detection_area_body_entered(body: Node3D) -> void:
	if "Player" in str(body):
		target = body
		print(body)
		print(body.position)
		print(body.global_position)
		chase_player = true


# Function to follow the player
func follow_player():
	if chase_player == true:
		position.x += (target.position.x - position.x)/speed
		position.z += (target.position.z - position.z)/speed
		move_and_slide()


# Stop following the player if they leave the detection area
func _on_player_detection_area_body_exited(body: Node3D) -> void:
	if "Player" in str(body):
		chase_player = false


# When the player is in damage dealing range, do damage
func _on_damage_dealing_range_body_entered(body: Node3D) -> void:
	if "Player" in str(body):
		doing_damage = true


# Function to deal damage to player
func damage_to_player():
	if doing_damage == true:
		if can_deal_damage == true:
			deal_damage.emit(damage)
			can_deal_damage = false
			$DamageCooldownTimer.start()


# Manage the damage cooldown from the enemy to the player
func _on_damage_cooldown_timer_timeout() -> void:
	can_deal_damage = true


# If the player leaves damage dealing range, stop doing damage
func _on_damage_dealing_range_body_exited(body: Node3D) -> void:
	if "Player" in str(body):
		doing_damage = false
