class_name RegisterServerDTO

var Name : String
var IPAddress : String
var Port : String
var MaxPlayers : int

func save_dict() -> Dictionary:
	var save_dict = {
		"Name" : Name,
		"IPAddress" : IPAddress,
		"Port" : Port,
		"MaxPlayers" : MaxPlayers
	}
	return save_dict
