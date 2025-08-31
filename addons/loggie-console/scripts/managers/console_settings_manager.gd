class_name ConsoleSettingsManager extends RefCounted

## Manages persistent storage of LoggieConsole settings
##
## Provides robust save/load functionality with automatic backup creation and
## comprehensive error handling. Settings are saved immediately when requested
## (no debouncing) and loaded with fallback to backup file or defaults.

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")

# File paths and configuration
const SETTINGS_PATH = "user://loggie_console_settings.tres"
const BACKUP_PATH = "user://loggie_console_settings_backup.tres"
const SETTINGS_RESOURCE_TYPE = "LoggieConsoleSettings"

## Loads console settings with comprehensive error handling and fallback chain
## 
## Load order: primary file → backup file → create defaults
## All loaded settings are validated and sanitized before returning.
## Returns: A valid LoggieConsoleSettings instance (never null)
func load_settings() -> LoggieConsoleSettings:
	var settings: LoggieConsoleSettings = null
	
	# Attempt to load primary settings file
	settings = _try_load_file(SETTINGS_PATH, "main settings")
	
	# Fall back to backup file if primary failed
	if settings == null:
		settings = _try_load_file(BACKUP_PATH, "backup settings")
	
	# Create default settings if both files failed
	if settings == null:
		Loggie.msg("Creating default console settings").domain(LoggieConsoleConstants.DOMAIN).info()
		settings = LoggieConsoleSettings.new()
	
	# Always validate to ensure data integrity
	settings.validate()
	
	Loggie.msg("Console settings loaded successfully").domain(LoggieConsoleConstants.DOMAIN).debug()
	return settings

## Saves console settings to disk immediately with backup creation
##
## Creates a backup of the existing file before saving, then validates
## the settings and writes them using Godot's ResourceSaver.
## Param settings: The settings to save (must not be null)
## Returns: true if save succeeded, false if it failed
func save_settings(settings: LoggieConsoleSettings) -> bool:
	return _save_with_backup(settings)

## Attempts to load a settings file with error handling
## Param path: File path to load from
## Param description: Human-readable description for logging
## Returns: Loaded settings or null if loading failed
func _try_load_file(path: String, description: String) -> LoggieConsoleSettings:
	if not FileAccess.file_exists(path):
		Loggie.msg("Settings file not found: %s" % path).domain(LoggieConsoleConstants.DOMAIN).debug()
		return null
	
	var resource: Resource = ResourceLoader.load(path, SETTINGS_RESOURCE_TYPE)
	if resource == null:
		Loggie.msg("Failed to load %s from: %s" % [description, path]).domain(LoggieConsoleConstants.DOMAIN).warn()
		return null
	
	if not resource is LoggieConsoleSettings:
		Loggie.msg("Invalid resource type in %s: %s" % [description, path]).domain(LoggieConsoleConstants.DOMAIN).error()
		return null
	
	Loggie.msg("Loaded %s from: %s" % [description, path]).domain(LoggieConsoleConstants.DOMAIN).debug()
	return resource as LoggieConsoleSettings

## Saves settings with automatic backup creation
## Param settings: The settings to save
## Returns: true if save succeeded, false otherwise
func _save_with_backup(settings: LoggieConsoleSettings) -> bool:
	if not settings:
		Loggie.msg("Cannot save null settings").domain(LoggieConsoleConstants.DOMAIN).error()
		return false
	
	# Validate settings before saving
	settings.validate()
	
	# Create backup of existing file before overwriting
	if FileAccess.file_exists(SETTINGS_PATH):
		var dir: DirAccess = DirAccess.open("user://")
		if dir:
			dir.copy(SETTINGS_PATH, BACKUP_PATH)
	
	# Save the validated settings
	var error: Error = ResourceSaver.save(settings, SETTINGS_PATH)
	if error != OK:
		Loggie.msg("Failed to save console settings: %s" % error_string(error)).domain(LoggieConsoleConstants.DOMAIN).error()
		return false
	
	Loggie.msg("Console settings saved successfully").domain(LoggieConsoleConstants.DOMAIN).debug()
	return true
