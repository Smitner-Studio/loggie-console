@tool
class_name LoggieConsoleEditorPlugin extends EditorPlugin

const AUTOLOAD_NAME: StringName = &"LoggieConsoleAutoload"
# Using class_name globals directly instead of const preloads to avoid name conflicts

var _color_settings: LoggieConsoleColorSettings

func _enter_tree() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, "res://addons/loggie-console/scenes/console.tscn")
	
	# Load or create color settings
	_load_color_settings()
	
	# Add project settings tab
	_create_project_settings_tab()
	
	# Connect to project settings changes
	if not ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.connect(_on_project_settings_changed)

func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	
	# Disconnect from project settings changes
	if ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
		ProjectSettings.settings_changed.disconnect(_on_project_settings_changed)
	
	# Remove project settings tab
	_remove_project_settings_tab()
	
	# Save color settings
	_save_color_settings()

func _enable_plugin() -> void:
	print("%s enabled" % AUTOLOAD_NAME)

func _disable_plugin() -> void:
	print("%s disabled" % AUTOLOAD_NAME)

func _create_project_settings_tab() -> void:
	# Add project settings for LoggieConsole colors under Project > Project Settings > Loggie Console
	# Simplified theme-based color management system
	
	# Main theme selection - provides dropdown with popular terminal themes
	_add_project_setting(&"loggie_console/colors/theme_name", "GruvBox Dark", TYPE_STRING, 
		"Color theme for domain highlighting in the console. Choose from popular, well-tested terminal themes.")
	
	# Color variation system - extends palettes beyond base colors
	_add_project_setting(&"loggie_console/colors/enable_color_variations", true, TYPE_BOOL,
		"Generate color variations when more domains exist than 20 theme colors. Disabling will cycle through the base palette colors.")
	_add_project_setting(&"loggie_console/colors/variation_brightness_factor", LoggieConsoleColorSettings.DEFAULT_BRIGHTNESS_FACTOR, TYPE_FLOAT,
		"Brightness multiplier for color variations (%g-%g). Higher values create brighter variations." % [LoggieConsoleColorSettings.MIN_BRIGHTNESS_FACTOR, LoggieConsoleColorSettings.MAX_BRIGHTNESS_FACTOR])
	_add_project_setting(&"loggie_console/colors/variation_saturation_factor", LoggieConsoleColorSettings.DEFAULT_SATURATION_FACTOR, TYPE_FLOAT,
		"Saturation multiplier for color variations (%g-%g). Lower values create more muted/pastel variations." % [LoggieConsoleColorSettings.MIN_SATURATION_FACTOR, LoggieConsoleColorSettings.MAX_SATURATION_FACTOR])
	

func _remove_project_settings_tab() -> void:
	# Remove project settings
	if ProjectSettings.has_setting(&"loggie_console/colors/theme_name"):
		ProjectSettings.clear(&"loggie_console/colors/theme_name")
	if ProjectSettings.has_setting(&"loggie_console/colors/enable_color_variations"):
		ProjectSettings.clear(&"loggie_console/colors/enable_color_variations")
	if ProjectSettings.has_setting(&"loggie_console/colors/variation_brightness_factor"):
		ProjectSettings.clear(&"loggie_console/colors/variation_brightness_factor")
	if ProjectSettings.has_setting(&"loggie_console/colors/variation_saturation_factor"):
		ProjectSettings.clear(&"loggie_console/colors/variation_saturation_factor")

func _add_project_setting(setting_name: StringName, default_value: Variant, type: int, documentation: String = "") -> void:
	if not ProjectSettings.has_setting(setting_name):
		ProjectSettings.set_setting(setting_name, default_value)
	
	ProjectSettings.set_initial_value(setting_name, default_value)
	
	var property_info: Dictionary = {
		"name": setting_name,
		"type": type,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	}
	
	# Add specific property hints based on the setting
	match setting_name:
		&"loggie_console/colors/theme_name":
			property_info["hint"] = PROPERTY_HINT_ENUM
			property_info["hint_string"] = "GruvBox Dark,Dracula,Monokai,Solarized Dark,One Dark,Nord"
		&"loggie_console/colors/variation_brightness_factor":
			property_info["hint"] = PROPERTY_HINT_RANGE
			property_info["hint_string"] = "%g,%g,0.1,or_greater,or_lesser,suffix: (brightness multiplier)" % [LoggieConsoleColorSettings.MIN_BRIGHTNESS_FACTOR, LoggieConsoleColorSettings.MAX_BRIGHTNESS_FACTOR]
		&"loggie_console/colors/variation_saturation_factor":
			property_info["hint"] = PROPERTY_HINT_RANGE
			property_info["hint_string"] = "%g,%g,0.1,or_greater,or_lesser,suffix: (saturation multiplier)" % [LoggieConsoleColorSettings.MIN_SATURATION_FACTOR, LoggieConsoleColorSettings.MAX_SATURATION_FACTOR]
	
	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_as_basic(setting_name, true)  # This makes it visible in Project Settings!
	
	# Set documentation tooltip if provided
	if not documentation.is_empty():
		# Note: ProjectSettings doesn't support tooltips directly, but we can add descriptive hint_string
		# The documentation is preserved for future reference
		pass
	
	var error: int = ProjectSettings.save()
	if error != OK:
		push_error("LoggieConsole - Error %d while saving project settings" % error)

func _load_color_settings() -> void:
	# Load settings from project settings
	_color_settings = LoggieConsoleColorSettings.new()
	
	if ProjectSettings.has_setting("loggie_console/colors/theme_name"):
		var theme_name: String = ProjectSettings.get_setting(&"loggie_console/colors/theme_name", "GruvBox Dark")
		_color_settings.apply_theme(theme_name)  # This sets the correct palette for the theme
		
		# Then load other settings
		_color_settings.enable_color_variations = ProjectSettings.get_setting(&"loggie_console/colors/enable_color_variations", true)
		_color_settings.variation_brightness_factor = ProjectSettings.get_setting(&"loggie_console/colors/variation_brightness_factor", LoggieConsoleColorSettings.DEFAULT_BRIGHTNESS_FACTOR)
		_color_settings.variation_saturation_factor = ProjectSettings.get_setting(&"loggie_console/colors/variation_saturation_factor", LoggieConsoleColorSettings.DEFAULT_SATURATION_FACTOR)

func _save_color_settings() -> void:
	if _color_settings:
		ProjectSettings.set_setting(&"loggie_console/colors/theme_name", _color_settings.theme_name)
		ProjectSettings.set_setting(&"loggie_console/colors/enable_color_variations", _color_settings.enable_color_variations)
		ProjectSettings.set_setting(&"loggie_console/colors/variation_brightness_factor", _color_settings.variation_brightness_factor)
		ProjectSettings.set_setting(&"loggie_console/colors/variation_saturation_factor", _color_settings.variation_saturation_factor)
		ProjectSettings.save()

func _on_project_settings_changed() -> void:
	# React to theme changes in project settings
	if _color_settings and ProjectSettings.has_setting("loggie_console/colors/theme_name"):
		var new_theme: String = ProjectSettings.get_setting(&"loggie_console/colors/theme_name", "GruvBox Dark")
		
		# Only update if theme actually changed
		if new_theme != _color_settings.theme_name:
			# Apply the new theme
			_color_settings.apply_theme(new_theme)
			print("LoggieConsole: Applied theme '%s'" % new_theme)
		
		# Sync other settings
		_sync_settings_from_project()

func _sync_settings_from_project() -> void:
	# Update color settings from project settings (called when project settings change)
	if _color_settings:
		_color_settings.enable_color_variations = ProjectSettings.get_setting(&"loggie_console/colors/enable_color_variations", true)
		_color_settings.variation_brightness_factor = ProjectSettings.get_setting(&"loggie_console/colors/variation_brightness_factor", LoggieConsoleColorSettings.DEFAULT_BRIGHTNESS_FACTOR)
		_color_settings.variation_saturation_factor = ProjectSettings.get_setting(&"loggie_console/colors/variation_saturation_factor", LoggieConsoleColorSettings.DEFAULT_SATURATION_FACTOR)
