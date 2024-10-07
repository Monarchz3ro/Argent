class_name AbstractFS extends RefCounted

#region FILESYSTEM VARIABLES
var label: String
var parent: Directory
var type: String
var permissions: String = "rwxrwxrwx"
var size: int:
	get:
		return self.get_size()
var last_modified: String = "12 October 2096"
var owned_by: String
var group: String
var metadata: Dictionary
#endregion

func _to_string() -> String:
	if self.type == "Directory":
		return label+"/"
	elif self.type == "Filetype":
		return label
	else:
		AbstractFS.panic("Nonexistent filetype detected: "+self.type)
		return "what the flying fuck"

func get_size() -> int:
	if self.type == "Filetype":
		return self.content.length()
	elif self.type == "Directory":
		var sizec: int = 0
		for child in self.children:
			sizec += child.get_size()
		return sizec
	else:
		AbstractFS.panic("Fetch size for nonexistent filetype "+self.type)
		return -1

func has_parent_named(lbl: String) -> bool:
	if self.parent.label == lbl:
		return true
	else:
		return false

static func panic(reason: String) -> void:
	while true:
		print("!!KERNEL PANIC!! Reason: "+reason)

func get_full_path_str() -> String:
	var current_fs: AbstractFS = self
	var stringstack: String = ""
	while current_fs.label != "":
		if current_fs.parent == null:
			AbstractFS.panic("Orphaned file found!")
			return "ORPHANED_FILE_ERROR"
		stringstack = current_fs._to_string() + stringstack
		current_fs = current_fs.parent
	return "/"+stringstack

func clone() -> AbstractFS:
	var cloned_fs: AbstractFS
	
	if self.type == "Directory":
		cloned_fs = Directory.new()  
	elif self.type == "Filetype":
		cloned_fs = Filetype.new(self.content)
	else:
		AbstractFS.panic("Unknown filetype: " + self.type)
		return null
	
	#clone common
	cloned_fs.label = self.label
	cloned_fs.permissions = self.permissions
	cloned_fs.last_modified = self.last_modified
	cloned_fs.owned_by = self.owned_by
	cloned_fs.group = self.group
	
	#clone meta
	cloned_fs.metadata = {}
	for key in self.metadata.keys():
		cloned_fs.metadata[key] = self.metadata[key]
	
	#if you clone the parent, it might lead to circular refs!! don't do that, fuckass
	cloned_fs.parent = null
	
	#recursively clone children of a dir
	if self.type == "Directory":
		cloned_fs.children.assign([])
		for child in self.children:
			var cloned_child = child.clone()  
			cloned_child.parent = cloned_fs
			cloned_fs.children.append(cloned_child)

	return cloned_fs

func selfdestruct() -> void:
	var parent_dir = self.parent
	self.parent = null
	parent_dir.children.erase(self)
