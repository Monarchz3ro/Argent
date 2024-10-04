class_name ls extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	#if there are any args or flags at all
	if len(args+flags) != 0:
		return Option.error("ls currently only supports 'ls'")
	
	var children = act.rwxapi_list_dir(act.active_user, act.current_directory)
	
	return children
