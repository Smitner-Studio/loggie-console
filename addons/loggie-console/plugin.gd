@tool
class_name LoggieConsoleEditorPlugin extends EditorPlugin

const AUTOLOAD_NAME = &"LoggieConsole"

func _enter_tree():
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/loggie-console/scenes/console.tscn")

func _exit_tree():
	remove_autoload_singleton(AUTOLOAD_NAME)

func _enable_plugin() -> void:
	print("%s enabled" % AUTOLOAD_NAME)

func _disable_plugin() -> void:
	print("%s disabled" % AUTOLOAD_NAME)
