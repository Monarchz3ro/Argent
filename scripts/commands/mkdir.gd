class_name mkdir extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	
	if flags:
		return Option.error("No flags supported as of now.")
	
	for argument in args:
		var opt: Option = act.rwxapi_makedir_user(act.active_user, act.current_directory, argument)
		if not opt.status():
			return opt
	
	return Option.OK([])
