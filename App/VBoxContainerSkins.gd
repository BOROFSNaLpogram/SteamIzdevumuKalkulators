extends VBoxContainer

var list_total_cost 
var current_user
var skin_name
var skin_cost
var skin_cost_taxed
var skin_list

var db : SQLite

func _ready():
	_update_list()


func _on_button_add_skin_pressed():
	skin_name = $HBoxContainerInputs/LineEnterSkinName.text #Iegūst nosaukuma tekstu
	skin_cost = $HBoxContainerInputs/LineEnterSkinPrice.text #Iegūst cenas tekstu
	
	if skin_name != "" and $HBoxContainerInputs/LineEnterSkinPrice.text != "": #Pārbauda, vai ir ievadīti dati
		if skin_cost.is_valid_float() and float(skin_cost) > 0: #Pārbauda, vai ir ievadīts derīgs skaitlis
			skin_cost = "%.2f"%float(skin_cost) #"%.2f"% noformē, lai ir 2 skaitļi decimālvietā
			skin_cost_taxed = "%.2f"%(float(skin_cost) / 1.15) #Aprēķina cenu pēc nodokļiem, noformē, lai ir 2 skaitļi decimālvietā
			
			$HBoxContainerInputs/LineEnterSkinName.text = "" #Attīra nosaukuma ievades lauciņu
			$HBoxContainerInputs/LineEnterSkinPrice.text = "" #Attīra cenas ievades lauciņu
			
			#Pievieno datu bāzē datus
			db.query_with_bindings("INSERT INTO skins (user_id, name, sell_cost, taxed_cost) VALUES (?, ?, ?, ?)", [current_user[0]["id"], skin_name, skin_cost, skin_cost_taxed])
			_update_list() #Izsauc _update_list() funkciju

func _on_button_clear_pressed():
	$ItemListSkins.clear() #Attīra ItemListSkins sarakstu
	skin_list = db.delete_rows("skins", "user_id = '" + str(current_user[0]["id"]) + "'") #Dzēš pašreizējā lietotāja ieroču kamoflāžas
	_update_list() #Izsauc _update_list() funkciju

func _on_button_remove_pressed():
	if $ItemListSkins.get_selected_items().size() > 0: #Pārbauda, vai ir izvēlēti vairāk par 0 elementiem
		db.query_with_bindings("DELETE FROM skins WHERE rowid IN (SELECT rowid FROM skins WHERE user_id = ? LIMIT 1 OFFSET ?)", [current_user[0]["id"], $ItemListSkins.get_selected_items()[0]])
		$ItemListSkins.remove_item($ItemListSkins.get_selected_items()[0]) #Noņem izvēlēto elementu
	_update_list() #Izsauc _update_list() funkciju

func _update_list():
	skin_list = db.select_rows("skins", "user_id = '" + str(current_user[0]["id"]) + "'", ["*"])
	$ItemListSkins.clear()
	for skin in skin_list:
		$ItemListSkins.add_item(skin["name"] + " (" + str("%.2f"%skin["sell_cost"]) + "€ ⇒ " + str("%.2f"%skin["taxed_cost"]) + "€)", null, true)
	get_parent().get_node("VBoxContainerGames")._update_total_cost()

func _update_total_cost(total_sum):
	list_total_cost = get_parent().get_node("VBoxContainerGames/ItemListCost") #Iegūst ItemListCost elementu
	list_total_cost.clear() #Attīra sarakstu kopējai summai
	
	if db == null: #Pārbauda, vai datu bāze neeksistē
		db = SQLite.new()
		db.path = "user://save-data.db"
		db.foreign_keys = true
		db.open_db()
		current_user = db.select_rows("users", "current_user = 1", ["*"])
	
	db.query_with_bindings("SELECT SUM(taxed_cost) FROM skins WHERE user_id = ?", [current_user[0]["id"]])
	var total_sum_skins = db.query_result[0]["SUM(taxed_cost)"] #Aprēķina kamoflāžu kopējo summu
	if total_sum_skins == null: total_sum_skins = 0 #Ja kamoflāžu kopējai summai nav vērtība, tiek piešķirta 0 kā vērtība
	
	list_total_cost.add_item(str("%.2f"%total_sum) + "€ - " + str("%.2f"%total_sum_skins) +"€", null, false) #Pievieno sarakstā elementu
	list_total_cost.add_item("= " + str("%.2f"%(total_sum - total_sum_skins)) + "€", null, false) #Pievieno sarakstā elementu
