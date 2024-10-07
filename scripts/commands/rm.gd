class_name rm extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	
	if flags:
		return Option.error("rm takes no flags.")
	if len(args) != 1:
		return Option.error("rm takes only one argument.")
	
	var target_str: String = args[0]
	var opt: Option = act.rwxapi_destroy(act.active_user, target_str)
	
	if not opt.status():
		return opt
	
	return Option.OK([])
