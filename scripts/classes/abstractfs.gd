class_name AbstractFS extends Node

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
