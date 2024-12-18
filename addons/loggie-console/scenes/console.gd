class_name LoggieConsole extends Window

@export var buffer: RichTextLabel


@export var output_level: OptionButton
@export var clear: Button

@export var scroll_follow: Button

@export_category("Collapse")
@export var collapse_texture: Texture2D
@export var uncollapse_texture: Texture2D
var collapsed := false

var _start_size: Vector2
var _last_size: Vector2

func _ready() -> void:
	Loggie.log_attempted.connect(_on_log_attempted)
	
	_start_size = DisplayServer.window_get_size() / 2
	_last_size = _start_size
	size = _start_size

	
	close_requested.connect(func():
		if collapsed:
			_expand_console()
		else:
			_collapse_console()
	)
	_expand_console()
	
	
	var current: String = (LoggieEnums.LogLevel.keys()[Loggie.settings.log_level])
	for value in LoggieEnums.LogLevel.values():
		var label: String = LoggieEnums.LogLevel.keys()[value]
		output_level.add_item(label, value)
	output_level.selected = Loggie.settings.log_level
		
	output_level.item_selected.connect(
		func(index: int):
			Loggie.settings.log_level = index
	)
	
	clear.pressed.connect(func():
		buffer.text = ""
		buffer.clear()
	)
	
	scroll_follow.toggled.connect(
		func(is_toggled: bool):
			Loggie.info(is_toggled)
			buffer.scroll_following = is_toggled
	)
	buffer.scroll_following = scroll_follow.button_pressed

func _on_log_attempted(msg : LoggieMsg, preprocessed_content : String, result : LoggieEnums.LogAttemptResult):
	if result == LoggieEnums.LogAttemptResult.SUCCESS:
		buffer.text += preprocessed_content + "\n"

func _expand_console() -> void:
	collapsed = false
	size = _last_size

	add_theme_icon_override("close", collapse_texture)
	add_theme_icon_override("close_pressed", collapse_texture)
	get_child(0).show()
	
func _collapse_console() -> void:
	collapsed = true
	_last_size = size
	size.y = 0
	add_theme_icon_override("close", uncollapse_texture)
	add_theme_icon_override("close_pressed", collapse_texture)
	get_child(0).hide()
