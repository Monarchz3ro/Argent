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
	var Err: Option = Option.new()
	Err.err = "No such child found!"
	
	for child in self.children:
		if child.label == lbl:
			Err.err = "OK"
			Err.result = child
			return Err
		
	return Err
