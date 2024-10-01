class_name Option extends Node

var result: Variant = null
var err: String = "OK"

func _init(res: Variant =null, ERROR: String ="OK") -> void:
	self.result = res
	self.err = ERROR

func status() -> bool:
	if self.result == null:
		return false
	else:
		return true

func unwrap() -> Variant:
	if not self.status():
		AbstractFS.panic("Unsafe unwrapping! "+self.err)
	return self.result

static func error(reason: String) -> Option:
	var error_option: Option = Option.new()
	error_option.err = reason
	return error_option

static func OK(wrap_with: Variant) -> Option:
	var status_option: Option = Option.new()
	status_option.result = wrap_with
	return status_option
