class_name LogLevelFilter extends OptionButton

## Standalone log level filter component
## Manages log level selection and syncs with Loggie settings

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")

# Signals
signal level_changed(new_level: LoggieEnums.LogLevel)

func _ready() -> void:
	_setup_level_options()
	item_selected.connect(_on_level_selected)
	tooltip_text = "Filter by log level"

## Initialize with current Loggie settings
func initialize() -> void:
	selected = Loggie.settings.log_level
	level_changed.emit(Loggie.settings.log_level)

## Get currently selected log level
func get_current_level() -> LoggieEnums.LogLevel:
	if selected >= 0 and selected < get_item_count():
		return get_item_id(selected) as LoggieEnums.LogLevel
	return LoggieEnums.LogLevel.DEBUG

## Set log level programmatically
func set_log_level(level: LoggieEnums.LogLevel) -> void:
	for i in range(get_item_count()):
		if get_item_id(i) == level:
			selected = i
			break

## Private methods

func _setup_level_options() -> void:
	clear()
	
	# Add all log levels as options
	for value in LoggieEnums.LogLevel.values():
		var label: String = LoggieEnums.LogLevel.keys()[value]
		add_item(label, value)

func _on_level_selected(index: int) -> void:
	var new_level = get_item_id(index) as LoggieEnums.LogLevel
	
	# Update Loggie settings
	Loggie.settings.log_level = new_level
	
	# Emit change signal
	level_changed.emit(new_level)

## Saves current log level selection to persistent settings
## Param settings: The settings resource to populate with current log level
func save_settings_to_resource(settings: LoggieConsoleSettings) -> void:
	settings.set_log_level(get_current_level())

## Loads log level selection from persistent settings and applies it
## Updates the UI control to reflect the loaded level without emitting change signals
## Param settings: The settings resource containing saved log level
func load_settings_from_resource(settings: LoggieConsoleSettings) -> void:
	set_log_level(settings.get_log_level())
