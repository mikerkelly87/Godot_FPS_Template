extends CanvasLayer

signal exit_pause_menu()


# Handle click on Quit button
func _on_quit_button_pressed():
	get_tree().quit()


# Handle click on Settings button
func _on_settings_button_pressed():
	$PauseControl.visible = false
	$SettingsControl.visible = true


# Handle click on restart button
func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

# Update mouse sensitivity after the player drags the slider
func _on_h_slider_drag_ended(value_changed):
	GameVars.mouse_sensitivity = $SettingsControl/CenterContainer/BoxContainer/VBoxContainer/ColorRect2/HSlider.value
	for i in range(51):
		if GameVars.mouse_sensitivity == i:
			GameVars.mouse_sensitivity = i * .001


# Handle back button click
func _on_back_button_pressed():
	$SettingsControl.visible = false
	$PauseControl.visible = true


func _on_resume_button_pressed():
	exit_pause_menu.emit()



