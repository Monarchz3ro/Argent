class_name Directory extends AbstractFS

var children: Array[AbstractFS] = []

func _init() -> void:
	self.type = "Directory"
	self.permissions = "d"+self.permissions

func makedir_sys(lbl: String, perms: String = "dr-x--x--x", owned: String = "root", in_group: String = "root") -> Directory:
	var newdir = Directory.new()
	newdir.label = lbl
	newdir.parent = self
	newdir.permissions = perms
	newdir.owned_by = owned
	newdir.group = in_group
	self.children.append(newdir)
	return newdir

func makedir_user(lbl: String, owned: String, in_group: String) -> Directory:
	var newdir = Directory.new()
	var perms: String = "drwxr-x--x"
	newdir.label = lbl
	newdir.permissions = perms
	newdir.owned_by = owned
	newdir.group = in_group
	newdir.parent = self
	self.children.append(newdir)
	return newdir


func writefile_sys(lbl: String, content: String, perms: String = "-r--------", owned: String = "root", in_group: String = "root") -> Filetype:
	var newfile = Filetype.new(content)
	newfile.parent = self
	newfile.label = lbl
	newfile.permissions = perms
	newfile.group = in_group
	newfile.owned_by = owned
	self.children.append(newfile)
	return newfile

func get_child_named(lbl: String) -> Option:
	for child in self.children:
		if child.label == lbl:
			return Option.OK(child)
	return Option.error("No such child found!")

func get_children_names() -> Array[String]:
	var res: Array[String] = []
	
	for child in self.children:
		res.append(child.label)
	
	return res
