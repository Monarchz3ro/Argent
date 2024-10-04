class_name cd extends Command

func action(act: Terminal, args: Array[String], flags: Array[String]):
#region error handling
	if flags:
		return Option.error("cd does not accept any flags.")
	
	if len(args) > 1:
		return Option.error("cd does not accept more than 1 argument.")
#endregion

	var target: String
	if not args:
		target = ""
	else:
		target = args[0]
	
	var opt: Option = act.rwxapi_changedir(target)
	
	if not opt.status():
		return opt
	else:
		return Option.OK([])
