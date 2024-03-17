extends Control

var db : SQLite

func _ready():
	db = SQLite.new()
	db.path = "user://save-data.db"
	db.foreign_keys = true
	db.open_db() #Atver datubāzi

func _clear():
	get_node("VBoxContainer/LineEditUsername").text = "" #Attīra lietotājvārda lauku
	get_node("VBoxContainer/LineEditPassword").text = "" #Attīra paroles lauku
	self.visible = false

func _on_button_sign_in_cancel_pressed():
	_clear()
	get_parent().get_node("VBoxContainerButtons").visible = true

func _on_button_sign_in_finish_pressed():
	var username = $VBoxContainer/LineEditUsername.text #Iegūst "LineEditUsername" elementa tekstu
	var password = $VBoxContainer/LineEditPassword.text #Iegūst "LineEditPassword" elementa tekstu
	
	var selected_user = db.select_rows("users", "username = '" + username + "'", ["*"])
	if username != "":
		if not selected_user.is_empty():
			if  selected_user[0]["password"] == password.sha256_text():
				db.update_rows("users", "current_user = 1", {"current_user" : 0})
				db.update_rows("users", "username = '" + username + "'", {"current_user" : 1})
				get_tree().change_scene_to_file("res://App/AppScene.tscn") #Pāriet uz aplikāciju
			else:
				_clear() #Izsauc _clear() funkciju
				get_parent().get_node("ErrorMessages/ControlIncorrectPassword").visible = true
		else:
			_clear()
			get_parent().get_node("ErrorMessages/ControlNoAccount").visible = true
	else:
		_clear()
		get_parent().get_node("ErrorMessages/ControlEnterUsername").visible = true

func _on_button_cancel_pressed():
	get_parent().get_node("ErrorMessages/ControlEnterUsername").visible = false
	get_parent().get_node("ErrorMessages/ControlNoAccount").visible = false
	get_parent().get_node("ErrorMessages/ControlIncorrectPassword").visible = false
	get_parent().get_node("ErrorMessages/ControlAccountExists").visible = false
	get_parent().get_node("VBoxContainerButtons").visible = true
