class_name Terminal extends Node2D

#region SYSTEM CRITICAL VARS
var root: Directory = Directory.new()
var autoboot_into: String = "root"
var active_user: String = autoboot_into
var default_write_group: String = "root"
var current_directory: Directory = root
var stack_tracker: Array[String] = [root.label]
var commands_dict: Dictionary
var PATH: Array[String] = ["/bin"]
var groups_and_members: Dictionary
#where this is the format:
#{ "groupname": {"GID":int, "members":Array[String]} }
#endregion

#region SYSTEM CRITICAL DIRECTORIES
#system critical dirs
var bin: Directory
var home: Directory
var playerhome: Directory
var boot: Directory
var lib: Directory
var etc: Directory
#endregion

func refresh_commands() -> void:
	commands_dict.clear()
	for path in PATH:
		var opt: Option = get_dir_at_path(path)
		if not opt.status():
			print("Failure while processing PATH variable: "+path+" "+opt.err)
			continue
		#now process all children of the necessary PATH
		var iteration: Directory = opt.unwrap()
		for child in iteration.children:
			#process children
			if child.type != "Filetype":
				continue #skip directories
			
			var meta = child.metadata
			if meta.has("executable_key"):
				commands_dict[child.label] = meta["executable_key"]

func get_dir_at_path(path: String) -> Option:
	var opt: Option = get_abfs_at_path(path)
	
	#if opt fails, return the error
	if not opt.status():
		return opt
	
	#if opt is not a dir, return an error
	if opt.unwrap().type != "Directory":
		return Option.new(null, "Target is not a directory!")
	
	#else all good to go! return the dir
	return opt

func get_file_at_path(path: String) -> Option:
	var opt: Option = get_abfs_at_path(path)
	
	#if opt flops, return the error
	if not opt.status():
		return opt
	
	#if opt is not a file, return an error
	if opt.unwrap().type != "Filetype":
		return Option.error("Target is not a file!")
	
	return opt

func stringify_stack() -> String:
	var stackstring: String = "/"
	for stack in stack_tracker:
		if not stack: 
			continue
		stackstring += stack+"/"
	return stackstring

func get_abfs_at_path(path: String) -> Option:
	#cast into abspath
	if path[0] != "/":
		path = stringify_stack() + path
	
	var path_stack = path.split("/")
	
	var directory_currently_held: AbstractFS
	if path[0] == "/":
		directory_currently_held = self.root
	else:
		directory_currently_held = self.current_directory  #or use curdir if relative
	
	for iterating_path in path_stack:
		if iterating_path == "":
			continue
		if directory_currently_held.type == "Filetype":
			return Option.error("A file cannot have children beneath it.")
		elif iterating_path == "..":
			directory_currently_held = directory_currently_held.parent
		elif iterating_path == ".":
			continue
		else:
			var option: Option = directory_currently_held.get_child_named(iterating_path)
			if not option.status():
				return option
			directory_currently_held = option.unwrap()
	
	return Option.OK(directory_currently_held)

func create_passwd_shadow_group(etc_dir: Directory) -> void:
	var passwd = etc_dir.writefile_sys("passwd", "")
	var shadow = etc_dir.writefile_sys("shadow", "")
	var groupsfile = etc_dir.writefile_sys("group", "")
	
	
	#username::password(x)::UID::GID::GECOS::home/directory::/bin/shell
	passwd.content = "monarch:x:00:00:Test user:/root:/bin/argent"
	
	shadow.content ="monarch:$5$salt$7a37b85c8918eac19a9089c0fa5a2ab4dce3f90528dcdeec108b23ddf3607b99:121096:0:99999:9999:0::"
	
	groupsfile.content = "monarch:00:monarch"

func fill_up_bin() -> void:
	materialise_command(ls.new(self), "ls")
	materialise_command(pwd.new(self), "pwd")
	materialise_command(mkdir.new(self), "mkdir")
	materialise_command(cd.new(self), "cd")
	materialise_command(rmdir.new(self), "rmdir")
	materialise_command(cp.new(self), "cp")
	materialise_command(mv.new(self), "mv")
	materialise_command(rm.new(self), "rm")
	materialise_command(uname.new(self), "uname")
	materialise_command(locate.new(self), "locate")

func materialise_command(comm: Command, with_name: String) -> Filetype:
	var command: Filetype = Filetype.new(with_name)
	command.metadata["executable_key"] = comm
	command.label = with_name
	bin.children.append(command)
	command.parent = bin
	return command

func initialise() -> void:
	root.permissions = "drwxr-x--x"
	print("Initialisation running")
	construct_default_fhs()
	refresh_commands()
	recognise_groups()
	print("Initialisation finished.")

func recognise_groups() -> void:
	var groupsfile: Option = get_file_at_path("/etc/group")
	if not groupsfile.status():
		print("No group detected whatsoever, logging in as guest.")
		autoboot_into = "guest"
		return
	var content: String = groupsfile.unwrap().content
	
	var grouplines: PackedStringArray = content.split("\n")
	
	for line in grouplines:
		var groupstrings: PackedStringArray = line.split(":")
		var groupname: String = groupstrings[0]
		var GID:String = groupstrings[1]
		var members_strings: String = groupstrings[2]
		var members: PackedStringArray = members_strings.split(",")
		
		if groups_and_members.has(groupname):
			print("Group name "+groupname+ " already exists.")
			continue
		
		var groupdict = {"GID":GID, "members": members}
		groups_and_members[groupname] = groupdict

func _init() -> void:
	initialise()

func construct_default_fhs() -> void:
	root.label = ""
	root.parent = root
	bin = root.makedir_sys("bin")
	fill_up_bin()
	boot = root.makedir_sys("boot")
	lib = root.makedir_sys("lib")
	home = root.makedir_sys("home")
	etc = root.makedir_sys("etc")
	create_passwd_shadow_group(etc)
	playerhome = home.makedir_sys("monarch", "dr-x--x--x", "monarch", "monarch")
	playerhome.makedir_sys("desktop", "dr-x--x--x", "monarch", "monarch")
	playerhome.makedir_sys("notes", "dr-x--x--x", "monarch", "monarch")
	#current_directory = etc

func execute_binding(command: String) -> Option:
	var exec_name = command.get_slice(" ", 0)
	
	if not commands_dict.has(exec_name):
		return Option.error("Command not found!")
	
	var Comm: Command = commands_dict[exec_name]
	
	return Comm.exec(command) #returns generic status (either OK or error)

###RWXAPI
#the RWX api is created for two purposes:
#1.to prevent frequent user verification and checking for scripting of command action()s
#	this is done by exposing functions with verification already built into them
#	into the terminal
#2.in case a scripting system is added, make it use this api under the hood to operate
#	(so the scripter doesn't accidentally get godmode by using something like 
#	Terminal.active_user = "root")

##helpers
func rwxapi_get_joined_groups(username: String) -> Array[String]:
	var groups_joined: Array[String] = []
	for key in groups_and_members:
		var groupdict: Dictionary = groups_and_members[key]
		var members_list: PackedStringArray = groupdict["members"]
		if username in members_list:
			groups_joined.push_back(key)
	
	#sorry if empty lmao
	return groups_joined

func rwxapi_get_relation(test_who: String, wrt: AbstractFS) -> String:
	#if the user is the owner of the file, they are the owner
	if wrt.owned_by == test_who:
		return "owner"
	#or if the user is part of the group that owns that file, they are in the group
	elif wrt.group in rwxapi_get_joined_groups(test_who):
		return "group"
	#if not, no luck
	else:
		return "others"

func rwxapi_allowed_to_perform(who: String, abfs: AbstractFS, operation: String) -> bool:
	var relation: String = rwxapi_get_relation(who, abfs)
	#now that you know the relation, check if the user is even allowed to perform that operation:
	if who == "root":
		return true #a root user can perform anything
		
	#the user can only perform operations defined by drwxrwxrwx (those 3 characters)
	elif relation == "owner": #                       ^^^
		if operation in abfs.permissions.substr(1,4):
			return true
		else:
			return false
	
	#next three for group
	elif relation == "group":
		if operation in abfs.permissions.substr(4,7):
			return true
		else:
			return false
	
	#otherwise look into the last three bits
	else:
		if operation in abfs.permissions.substr(7):
			return true
		else:
			return false

func locate_recursive(actor: String, current_dir: Directory, search_term: String, results: Array[String]) -> void:
	if not rwxapi_allowed_to_perform(actor, current_dir, "x"):
		return
	
	for child in current_dir.children:
		if child.label.findn(search_term) != -1:
			results.append(child.get_full_path_str())
		
		if child.type == "Directory":
			locate_recursive(actor, child, search_term, results)

##rwxapi main

func rwxapi_create_empty_file(actor: String, create_where: Directory, with_name: String) -> Option:
	
	#first, check if the actor is allowed to "w" the directory
	if not rwxapi_allowed_to_perform(actor, create_where, "w"):
		#print("Disallowed.")
		return Option.error("Forbidden write operation: cannot write to directory "+create_where.label)
	
	#then send off the empty file
	var file: Filetype = create_where.writefile_sys(with_name, "")
	#print("Write operation success.")
	return Option.OK(file)

func rwxapi_list_dir(actor: String, target: Directory) -> Option:
	
	#you must be able to "x" the directory to list its directories
	if not rwxapi_allowed_to_perform(actor, target, "x"):
		return Option.error("Forbidden execute operation: cannot list directory "+target.label)
	
	#then send off the list of dirs
	var children: Array[AbstractFS] = target.children
	return Option.OK(children)

func rwxapi_present_working_dir() -> Option:
	var present_dir: Directory = current_directory
	return Option.OK(present_dir)

func rwxapi_makedir_user(actor: String, create_where: Directory, with_name: String) -> Option:
	#to create a directory in target, you must be able to "w" to that dir
	if not rwxapi_allowed_to_perform(actor, create_where, "w"):
		return Option.error("Forbidden write operation: cannot write to directory "+create_where.label)
	
	#check if there are any dirs of the same name already in there
	if with_name in create_where.get_children_names():
		return Option.error("Filesystem object with the name "+with_name+" already exists!")
	
	var dir: Directory = create_where.makedir_user(with_name, active_user, default_write_group)
	return Option.OK(dir)

func rwxapi_changedir(go_where: String) -> Option:
	var current_dir: Directory = self.current_directory
	var target_opt: Option = current_dir.get_child_named(go_where)
	if not target_opt.status():
		return target_opt
	
	var target: Directory = target_opt.unwrap()
	
	#check if you're allowed to "x" that directory
	if not rwxapi_allowed_to_perform(self.active_user, target, "x"):
		return Option.error("Forbidden execute operation: Not allowed to enter Directory "+target.label)
	
	self.current_directory = target
	stack_tracker.assign(self.current_directory.get_full_path_str().split("/"))
	return Option.OK("OK")

func is_ancestral_dir(target: Directory) -> bool:
	
	#handle root case
	if target == self.root:
		return true
	
	var current_dir: Directory = self.current_directory
	while current_dir != root:
		if current_dir == target:
			return true
		current_dir = current_dir.parent
	return false

func rwxapi_removedir(target: String) -> Option:
	var target_path = self.current_directory.get_full_path_str() + target
	var opt: Option = self.get_dir_at_path(target_path)
	if not opt.status():
		return opt
	
	var target_dir: Directory = opt.unwrap()
	var target_parent: Directory = target_dir.parent
	
	if is_ancestral_dir(target_dir):
		return Option.error("Not allowed to destroy an ancestral directory!")
	
	if not rwxapi_allowed_to_perform(self.active_user, target_parent, "w"):
		return Option.error("Forbidden write operation: Cannot write to target's parent, thus cannot delete it.")
	
	target_dir.selfdestruct()
	return Option.OK(target_dir)

func rwxapi_copy(actor: String, source_path: String, dest_path: String) -> Option:
	# Check source exists
	print("Attempting to copy from source: ", source_path, " to destination: ", dest_path)
	var source_opt: Option = get_abfs_at_path(source_path)
	if not source_opt.status():
		print("Source not found: " + source_path)
		return Option.error("Source not found: " + source_path)
	var source_abfs: AbstractFS = source_opt.unwrap()
	print("Source found: ", source_abfs.label, " (Type: ", source_abfs.type, ")")

	var dest_parent_path: String
	var new_name: String

	# Check if the destination is a directory
	var dest_opt: Option = get_abfs_at_path(dest_path)
	if dest_opt.status() and dest_opt.unwrap().type == "Directory":
		# If the destination is an existing directory
		print("Destination is an existing directory.")
		dest_parent_path = dest_path
		new_name = source_abfs.label # Keep original name
	else:
		if dest_path.ends_with("/"): # Destination path looks like a directory
			print("Destination is intended to be a directory.")
			dest_parent_path = dest_path
			new_name = source_abfs.label # Keep original name
		else:
			print("Destination includes a new name.")
			# Find the last slash to separate parent directory and new file name
			var slash_pos = dest_path.rfind("/")
			print("Last slash position: ", str(slash_pos))
			if slash_pos == -1:
				dest_parent_path = "" # Treat as root if there's no slash at all
			else:
				dest_parent_path = dest_path.substr(0, slash_pos + 1) # Up to the last slash
			new_name = dest_path.substr(slash_pos + 1) # After the last slash
			print("Destination parent path: ", dest_parent_path)
			print("New name for the copied file/directory: ", new_name)

	# Check destination directory exists
	var dest_parent_opt: Option = get_dir_at_path(dest_parent_path)
	if not dest_parent_opt.status():
		print("Destination directory not found: " + dest_parent_path)
		return Option.error("Destination directory not found: " + dest_parent_path)
	var dest_dir: Directory = dest_parent_opt.unwrap()
	print("Destination directory found: ", dest_dir.label)

	# Verify write permissions for the actor on the destination directory
	if not rwxapi_allowed_to_perform(actor, dest_dir, "w"):
		print("Write permission denied for actor: ", actor, " on directory: ", dest_dir.label)
		return Option.error("Forbidden write operation: cannot write to directory " + dest_dir.label)
	print("Write permission granted for actor: ", actor)

	# Check if the destination already contains an object with the new name
	for child in dest_dir.children:
		print("Checking child: ", child.label)
		if child.label == new_name:
			print("A file or directory with the name " + new_name + " already exists in " + dest_dir.label)
			return Option.error("A file or directory with the name " + new_name + " already exists in " + dest_dir.label)

	# Perform the actual copying
	print("Cloning the source...")
	var cloned_abfs: AbstractFS = source_abfs.clone()
	cloned_abfs.label = new_name # Apply the new name (if any)
	cloned_abfs.parent = dest_dir
	print("Appending cloned object with label: ", cloned_abfs.label, " to destination directory: ", dest_dir.label)
	dest_dir.children.append(cloned_abfs)

	print("Copy operation successful.")
	return Option.OK(cloned_abfs)

func rwxapi_move(actor: String, source_path: String, dest_path: String) -> Option:
	# Check source exists
	print("Attempting to copy from source: ", source_path, " to destination: ", dest_path)
	var source_opt: Option = get_abfs_at_path(source_path)
	if not source_opt.status():
		print("Source not found: " + source_path)
		return Option.error("Source not found: " + source_path)
	var source_abfs: AbstractFS = source_opt.unwrap()
	print("Source found: ", source_abfs.label, " (Type: ", source_abfs.type, ")")

	var dest_parent_path: String
	var new_name: String

	# Check if the destination is a directory
	var dest_opt: Option = get_abfs_at_path(dest_path)
	if dest_opt.status() and dest_opt.unwrap().type == "Directory":
		# If the destination is an existing directory
		print("Destination is an existing directory.")
		dest_parent_path = dest_path
		new_name = source_abfs.label # Keep original name
	else:
		if dest_path.ends_with("/"): # Destination path looks like a directory
			print("Destination is intended to be a directory.")
			dest_parent_path = dest_path
			new_name = source_abfs.label # Keep original name
		else:
			print("Destination includes a new name.")
			# Find the last slash to separate parent directory and new file name
			var slash_pos = dest_path.rfind("/")
			print("Last slash position: ", str(slash_pos))
			if slash_pos == -1:
				dest_parent_path = "" # Treat as root if there's no slash at all
			else:
				dest_parent_path = dest_path.substr(0, slash_pos + 1) # Up to the last slash
			new_name = dest_path.substr(slash_pos + 1) # After the last slash
			print("Destination parent path: ", dest_parent_path)
			print("New name for the copied file/directory: ", new_name)

	# Check destination directory exists
	var dest_parent_opt: Option = get_dir_at_path(dest_parent_path)
	if not dest_parent_opt.status():
		print("Destination directory not found: " + dest_parent_path)
		return Option.error("Destination directory not found: " + dest_parent_path)
	var dest_dir: Directory = dest_parent_opt.unwrap()
	print("Destination directory found: ", dest_dir.label)

	# Verify write permissions for the actor on the destination directory
	if not rwxapi_allowed_to_perform(actor, dest_dir, "w"):
		print("Write permission denied for actor: ", actor, " on directory: ", dest_dir.label)
		return Option.error("Forbidden write operation: cannot write to directory " + dest_dir.label)
	print("Write permission granted for actor: ", actor)

	# Check if the destination already contains an object with the new name
	for child in dest_dir.children:
		print("Checking child: ", child.label)
		if child.label == new_name:
			print("A file or directory with the name " + new_name + " already exists in " + dest_dir.label)
			return Option.error("A file or directory with the name " + new_name + " already exists in " + dest_dir.label)

	# Perform the actual moving
	print("Cloning the source...")
	var cloned_abfs: AbstractFS = source_abfs.clone()
	cloned_abfs.label = new_name # Apply the new name (if any)
	cloned_abfs.parent = dest_dir
	print("Appending cloned object with label: ", cloned_abfs.label, " to destination directory: ", dest_dir.label)
	dest_dir.children.append(cloned_abfs)
	#Now free the source
	source_abfs.selfdestruct()
	print("Source file freed. Move complete.")
	return Option.OK(cloned_abfs)

func rwxapi_destroy(actor: String, target: String) -> Option:
	var opt: Option = get_abfs_at_path(target)
	if not opt:
		return opt
	
	var target_abfs: AbstractFS = opt.unwrap()
	
	if target_abfs.type == "Directory":
		if is_ancestral_dir(target_abfs):
			return Option.error("Not allowed to destroy an ancestral directory!")
	
	if not rwxapi_allowed_to_perform(actor, target_abfs, "w"):
		return Option.error("Forbidden write operation: failed to write to "+target_abfs.label)
	
	if not rwxapi_allowed_to_perform(actor, target_abfs, "x"):
		return Option.error("Forbidden execute operation: failed to execute "+target_abfs.label)
	
	target_abfs.selfdestruct()
	
	return Option.OK("Target destroyed.")

func rwxapi_locate(actor: String, search_term: String, start_dir: Directory = self.root) -> Option:
	var matches: Array[String] = []
	locate_recursive(actor, start_dir, search_term, matches)
	if matches.size() == 0:
		return Option.error("No matches found for: " + search_term)
	return Option.OK(matches)
