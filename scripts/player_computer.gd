extends Computer

@export var buffer: LineEdit

func _on_line_edit_text_submitted(new_text: String) -> void:
	buffer.clear()
	execute_command(new_text)
