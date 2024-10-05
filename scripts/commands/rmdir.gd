class_name rmdir extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	if len(args+flags) == 0:
		return Option.error("No target specified.")
	if flags:
		return Option.error("rmdir takes no flags.")
	if len(args) > 1:
		return Option.error("rmdir takes only one target.")
	
	var target_str: String = args[0]
	var opt: Option = act.rwxapi_removedir(target_str)
	if not opt.status():
		return opt
	
	return Option.OK([])
