class_name Terminal extends Node2D

#region SYSTEM CRITICAL VARS
var root: Directory = Directory.new()
var autoboot_into: String = "monarch"
var active_user: String = autoboot_into
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
		else:
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
		stackstring += stack+"/"
	return "/"+stackstring

func get_abfs_at_path(path: String) -> Option:
	
	var OutputError: Option = Option.new()
	
	#turn it into absolute
	if path[0] != "/":
		path = stringify_stack() + path
	
	#split up into paths
	var path_stack = path.split("/")
	
	var directory_currently_held: AbstractFS = self.root
	
	for iterating_path in path_stack:
		if directory_currently_held.type == "Filetype":
			OutputError.err = "A file cannot have children beneath it."
			return OutputError
		elif iterating_path == "..":
			directory_currently_held = directory_currently_held.parent
		elif iterating_path == ".":
			continue
		elif iterating_path == "":
			directory_currently_held = root
		else:
			var option: Option = directory_currently_held.get_child_named(iterating_path)
			if option.status():
				directory_currently_held = option.result
			else:
				return option
	
	OutputError.result = directory_currently_held
	OutputError.err = "OK"
	
	return OutputError 

func create_passwd_shadow_group(etc_dir: Directory) -> void:
	var passwd = etc_dir.writefile_sys("passwd", "")
	var shadow = etc_dir.writefile_sys("shadow", "")
	var groupsfile = etc_dir.writefile_sys("group", "")
	
	
	#username::password(x)::UID::GID::GECOS::home/directory::/bin/shell
	passwd.content = "monarch:x:00:00:Test user:/root:/bin/argent"
	
	shadow.content ="monarch:$5$salt$7a37b85c8918eac19a9089c0fa5a2ab4dce3f90528dcdeec108b23ddf3607b99:121096:0:99999:9999:0::"
	
	groupsfile.content = "monarch:00:monarch"

func fill_up_bin(binary_folder: Directory) -> void:
	materialise_command(ls.new(self), "ls")
	materialise_command(pwd.new(self), "pwd")
	

func materialise_command(comm: Command, with_name: String) -> Filetype:
	var command: Filetype = Filetype.new(with_name)
	command.metadata["executable_key"] = comm
	command.label = with_name
	command.parent = bin
	bin.children.append(command)
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
	fill_up_bin(bin)
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
	
##for files
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

##for directories
#func rwxapi_change_dir(actor: String, target: Directory) -> Option:
	#AbstractFS.panic("NOT IMPLEMENTED ERROR")
	#return Option.error("")

func rwxapi_present_working_dir(actor: String) -> Option:
	var pwd: Directory = current_directory
	return Option.OK(pwd)
