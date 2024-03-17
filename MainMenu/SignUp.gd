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

func _on_button_sign_up_cancel_pressed():
	_clear() #Izsauc _clear() funkciju
	get_parent().get_node("VBoxContainerButtons").visible = true

func _on_button_sign_up_finish_pressed():
	var username = $VBoxContainer/LineEditUsername.text #Iegūst "LineEditUsername" elementa tekstu
	var password = $VBoxContainer/LineEditPassword.text #Iegūst "LineEditPassword" elementa tekstu
	
	
	var table_users = {
		"id" : {"data_type" : "int", "primary_key" : true, "not_null" : true, "auto_increment" : true},
		"username" : {"data_type" : "text", "not_null" : true},
		"password" : {"data_type" : "text"},
		"current_user" : {"data_type" : "int"}
	}
	db.create_table("users", table_users)
	
	var table_games = {
		"user_id" : {"data_type" : "int", "foreign_key" : "users.id"},
		"name" : {"data_type" : "text"},
		"cost" : {"data_type" : "real"}
	}
	db.create_table("games", table_games)
	
	var table_skins = {
		"user_id" : {"data_type" : "int", "foreign_key" : "users.id"},
		"name" : {"data_type" : "text"},
		"sell_cost" : {"data_type" : "real"},
		"taxed_cost" : {"data_type" : "real"}
	}
	db.create_table("skins", table_skins)
	
	
	var check_name = db.select_rows("users", "username = '" + username + "'", ["*"])
	if username != "":
		if check_name.size() == 0:
			db.update_rows("users", "current_user = 1", {"current_user" : 0})
			var data = {
				"username" : username,
				"password" : password.sha256_text(), #Šifrē paroli izmantojot SHA-256 algoritmu
				"current_user" : 1
			}
			db.insert_row("users", data)
			
			get_tree().change_scene_to_file("res://App/AppScene.tscn") #Pāriet uz aplikāciju
		else:
			_clear()
			get_parent().get_node("ErrorMessages/ControlAccountExists").visible = true
			
	else:
		_clear()
		get_parent().get_node("ErrorMessages/ControlEnterUsername").visible = true
