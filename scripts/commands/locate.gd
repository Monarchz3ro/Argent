class_name locate extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]) -> Option:
	if flags:
		return Option.error("locate does not accept any flags.")
	if len(args) != 1:
		return Option.error("locate takes only one argument.")
	
	var target_str: String = args[0]
	
	var located: Option = act.rwxapi_locate(act.active_user, target_str)
	
	if not located.status():
		return located
	
	var matches: Array[String] = located.unwrap()
	
	return Option.OK(matches)
