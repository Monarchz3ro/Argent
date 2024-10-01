class_name Filetype extends AbstractFS

var content: String = ""

func _init(c: String) -> void:
	self.type = "Filetype"
	self.permissions = "-"+self.permissions
	self.content = c

func append(item: String):
	self.content += item

func overwrite(item: String):
	self.content = item

func clear():
	self.content = ""
