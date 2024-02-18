extends RefCounted
class_name DAO
var db 


func _init():
	db = SQLite.new()
	db.path="res://data.db"
	db.open_db()
	CreateTableinDB()

func CreateTableinDB():
	var table = {
		"id" : {"data_type":"int", "primary_key": true, "not_null" : true, "auto_increment" : true},
		"name" : {"data_type":"text"},
		"password" : {"data_type":"text"},
		"rating" : {"data_type" : "int"},
		"salt" : {"data_type" : "int", "not_null" : true},
		"score" : {"data_type" : "int", "not_null" : true},
		"win" : {"data_type" : "int", "not_null" : true},
		"loss" : {"data_type" : "int", "not_null" : true},
	}
	db.create_table("players", table)


func InsertUserData(name, password, salt):
	var data = {
		"name" : name,
		"password" : password,
		"salt" : salt,
		"rating" : 1000
	}
	
	db.insert_row("players", data)
	pass # Replace with function body.

func get_user_from_database(username):
	var query = db.query("SELECT salt, password FROM players WHERE name = '" + username + "'")
	
	for i in db.query_result:
		# Assuming `query` returns an array of dictionaries where each dictionary represents a row
		
		return {
			"salt": i["salt"],
			"hashed_password": i["password"]
		}
	
func get_user_data_from_database(username):
	var query = db.query("SELECT Score, win, loss, id, rating FROM players WHERE name = '" + username + "'")
	
	for i in db.query_result:
		# Assuming `query` returns an array of dictionaries where each dictionary represents a row
		
		return {
			"id": i["id"],
			"rating": i["rating"],
			"score": i["Score"],
			"win": i["Win"],
			"loss": i["Loss"]
		}
