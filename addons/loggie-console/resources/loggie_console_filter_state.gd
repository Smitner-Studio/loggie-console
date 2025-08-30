@tool
class_name LoggieConsoleFilterState extends Resource

## Persistent filter state resource for LoggieConsole
## 
## Stores filtering criteria (domains, log levels, search terms) in a format compatible
## with Godot's Resource system while maintaining compatibility with LogBuffer.FilterState.
## This enables console filter settings to persist between application sessions.


## List of domain names that are currently enabled for display
@export var enabled_domains: Array[String] = []

## Minimum log level to display (stored as int for persistence compatibility)
@export var min_log_level: int = LoggieEnums.LogLevel.DEBUG

## Text search filter - only messages containing this text will be shown
@export var text_search: String = ""

## Whether to show only messages that include stack traces
@export var show_stack_only: bool = false

## Converts this persistent resource to runtime FilterState object
## Returns: A new LogBuffer.FilterState instance with matching filter criteria
func to_filter_state() -> LogBuffer.FilterState:
	var filter_state: LogBuffer.FilterState = LogBuffer.FilterState.new()
	filter_state.enabled_domains = enabled_domains.duplicate()
	filter_state.min_log_level = min_log_level as LoggieEnums.LogLevel
	filter_state.text_search = text_search
	filter_state.show_stack_only = show_stack_only
	return filter_state

## Populates this resource from runtime FilterState object
## Param filter_state: The LogBuffer.FilterState to copy data from
func from_filter_state(filter_state: LogBuffer.FilterState) -> void:
	enabled_domains = filter_state.enabled_domains.duplicate()
	min_log_level = filter_state.min_log_level as int
	text_search = filter_state.text_search
	show_stack_only = filter_state.show_stack_only

## Validates and sanitizes all data after loading from disk
## Ensures all fields have valid values even if the saved file was corrupted
func validate() -> void:
	# Ensure domain array exists
	if enabled_domains == null:
		enabled_domains = []
	
	# Validate log level is within valid enum range
	if min_log_level < 0 or min_log_level >= LoggieEnums.LogLevel.size():
		min_log_level = LoggieEnums.LogLevel.DEBUG
		Loggie.msg("Invalid log level, reset to DEBUG").domain(LoggieConsoleConstants.DOMAIN).warn()
	
	# Ensure search text is never null
	if text_search == null:
		text_search = ""
