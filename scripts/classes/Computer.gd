class_name Computer extends Node2D

var terminal: Terminal = Terminal.new()
var root: Directory = terminal.root

func _ready() -> void:
	pass

func execute_command(command: String):
	if not command:
		return
	
	var opt = terminal.execute_binding(command)
	
	if not opt.status():
		print(opt.err)
		return
	
	for line in opt.unwrap():
		print(line)
