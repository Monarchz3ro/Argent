class_name Command extends Node

var flagtype: String = "clc" #either mf or clc
var invoke_spell: String
var actor: Terminal
var target: Terminal

func _init(act: Terminal, targ: Terminal = actor) -> void:
	self.actor = act
	self.target = targ

func action(_actor: Terminal, _args: Array[String], _flags: Array[String]) -> Option:
	#this function is meant to be overwritten. this is just a demo.
	return Option.new()

func distill_flags(command: String) -> Array[Array]:
	var commands: PackedStringArray = command.split(" ")
	commands.remove_at(0)
	var args_arr: Array[String] = []
	var flags_arr: Array[String] = []
	
	#accept mf
	if self.flagtype == "mf":
		for argument in commands:
			if argument[0] == "-":
				flags_arr.append(argument.trim_prefix("-"))
			else:
				args_arr.append(argument)
	
	#accept clc
	elif self.flagtype == "clc":
		for argument in commands:
			if argument[0] == "-":
				var trimmed: String = argument.trim_prefix("-")
				for character in trimmed:
					flags_arr.append(character)
			else:
				args_arr.append(argument)
	
	return [args_arr, flags_arr]

func exec(command: String) -> Option:
	var distills: Array[Array] = distill_flags(command)
	var args: Array[String] = distills[0]
	var flags: Array[String] = distills[1]
	var opt: Option = action(actor, args, flags)
	return opt
