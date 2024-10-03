class_name pwd extends Command

func action(actor: Terminal, _args: Array[String], _flags: Array[String]) -> Option:
	var active_directory_opt: Option = actor.rwxapi_present_working_dir(actor.active_user)
	if not active_directory_opt.status():
		return Option.error("Somehow failed to fetch active dir.")
	
	var active_directory: Directory = active_directory_opt.unwrap()
	return Option.OK(active_directory.get_full_path_str())
