class_name LoginRequestDTO

var Username : String
var Password : String

func get_dict():
	var save_dict = {
		"Username" : Username,
		"Password" : Password
	}
	return save_dict
