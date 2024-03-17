extends Node

func _on_button_quit_pressed():
	get_tree().quit() #Aizver aplikāciju

func _on_button_sign_up_pressed():
	self.visible = false #Padara VBoxContainerButtons neredzamu
	get_parent().get_node("ControlSignUp").visible = true #Padara ControlSignUp redzamu
	
func _on_button_sign_in_pressed():
	self.visible = false
	get_parent().get_node("ControlSignIn").visible = true
