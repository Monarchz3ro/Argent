class_name cp extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	#region error handling
	if flags:
		return Option.error("cp does not accept any flags.")
	
	if len(args) < 2:
		return Option.error("cp requires at least two arguments: source and destination.")
	elif len(args) > 2:
		return Option.error("cp does not accept more than 2 arguments.")
	#endregion
	
	var source_str: String = args[0]
	var dest_str: String = args[1]
	
	#prayer phase
	var opt: Option = act.rwxapi_copy(act.active_user, source_str, dest_str)
	if not opt.status():
		return opt
	
	return Option.OK([])
