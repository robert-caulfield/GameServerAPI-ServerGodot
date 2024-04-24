extends Node

var arguments = {}

func _init():
	# populate arguments dictionary with command line arguments
	for argument in OS.get_cmdline_args():
		if argument.find("=") >- 1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
