extends VBoxContainer


var game_id
var total_cost
var current_user
var game_title
var game_price
var games_list

var db : SQLite


func _ready():
	db = SQLite.new()
	db.path = "user://save-data.db"
	db.foreign_keys = true
	db.open_db()
	current_user = db.select_rows("users", "current_user = 1", ["*"]) #Iegūst pašreizējo lietotāju
	_update_list()


func _on_http_request_request_completed(_result, _response_code, _headers, _body):
	var json = JSON.parse_string(_body.get_string_from_utf8()) #Iegūst lapas saturu kā JSON datni
		
	if json[game_id]["success"] == true and json[game_id]["data"]["release_date"]["coming_soon"] == false:
		game_title = json[game_id]["data"]["name"] #Iegūst spēles nosaukumu
		
		if json[game_id]["data"]["is_free"] == true: game_price = 0 #Ja spēle ir bez maksas, cenu iestata kā 0
		else: game_price = json[game_id]["data"]["price_overview"]["final"] / 100 #Dala cenu ar 100, lai iegūtu decimālskaitli
		
		db.query_with_bindings("INSERT INTO games (user_id, name, cost) VALUES (?, ?, ?)", [current_user[0]["id"], game_title, game_price]) #Datu bāzē izveido jaunu rindu
		_update_list()

func _on_button_back_pressed():
	get_tree().change_scene_to_file("res://MainMenu/MainMenuScene.tscn") #Pāriet uz sākuma ekrānu

func _on_button_add_game_pressed():
	game_id = $LineEnterGameID.text #Iegūst ievadīto spēles ID
	if game_id.is_valid_float(): #Pārbauda, vai spēles ID ir skaitliska vērtība
		$Node/HTTPRequest.request("https://store.steampowered.com/api/appdetails?appids=" + game_id + "&cc=lv") #Veic pieprasījumu, cc - country code (lv - Latvija)

func _on_button_clear_pressed():
	$ItemListGames.clear() #Attīra sarakstu
	games_list = db.delete_rows("games", "user_id = '" + str(current_user[0]["id"]) + "'") #Dzēš pašreizējā lietotāja spēles datu bāzē
	_update_list() #Izsauc _update_list() funkciju

func _on_button_remove_pressed():
	if $ItemListGames.get_selected_items().size() > 0: #Pārbauda, vai ir izvēlēti vairāk par 0 elementiem
		#No datu bāzes izvēles pašreizējā lietotāja spēles, dzēš rindu ar spēļu saraksta izvēlētā elementa indeksu 
		db.query_with_bindings("DELETE FROM games WHERE rowid IN (SELECT rowid FROM games WHERE user_id = ? LIMIT 1 OFFSET ?)", [current_user[0]["id"], $ItemListGames.get_selected_items()[0]])
		$ItemListGames.remove_item($ItemListGames.get_selected_items()[0]) #Noņem izvēlēto elementu
	_update_list()

func _update_list():
	games_list = db.select_rows("games", "user_id = '" + str(current_user[0]["id"]) + "'", ["*"]) #Iegūst visas pašreizējā lietotāja spēles
	$ItemListGames.clear() #Attīra spēļu sarakstu
	$LineEnterGameID.text = "" #Attīra ievades lauciņu
	for game in games_list:
		$ItemListGames.add_item(game["name"] + " (" + str("%.2f"%game["cost"]) + "€)", null, true) #Pievieno sarakstā spēli
	_update_total_cost() #Izsauc _update_total_cost() funkciju

func _update_total_cost():
	db.query_with_bindings("SELECT SUM(cost) FROM games WHERE user_id = ?", [current_user[0]["id"]])
	var total_sum = db.query_result[0]["SUM(cost)"] #Iegūst spēļu kopējo summu
	if total_sum == null: total_sum = 0 #Ja spēļu kopējai summai nav vērtība, tiek piešķirta 0 kā vērtība
	get_parent().get_node("VBoxContainerSkins")._update_total_cost(total_sum) #VBoxContainerSkins elementā izsauc _update_total_cost() funkciju ar total_sum parametru
