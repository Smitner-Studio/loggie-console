@tool
class_name LoggieConsoleSettings extends Resource

## Complete persistent settings for LoggieConsole
##
## This resource stores all console state including window properties, filter settings,
## component states, and discovered domains. It automatically saves when the console
## exits and loads on startup to restore the user's previous console configuration.

const LoggieConsoleFilterState = preload("res://addons/loggie-console/resources/loggie_console_filter_state.gd")
const LoggieConsoleColorSettings = preload("res://addons/loggie-console/resources/loggie_console_color_settings.gd")
const LoggieConsoleConstants = preload("res://addons/loggie-console/scripts/loggie_console_constants.gd")
const LoggieEnums = preload("res://addons/loggie/tools/loggie_enums.gd")

# Configuration constants
const MIN_WINDOW_WIDTH: int = 400
const MIN_WINDOW_HEIGHT: int = 300
const DEFAULT_WINDOW_WIDTH: int = 800
const DEFAULT_WINDOW_HEIGHT: int = 400
const SCREEN_MARGIN_PIXELS: int = 100  # 50px on each side
const WINDOW_EDGE_MARGIN: int = 20
const WINDOW_MIN_MARGIN: int = 10


## Filter state for log message display (domains, levels, search terms)
@export var filter_state: LoggieConsoleFilterState

## Color settings for domain color management
@export var color_settings: LoggieConsoleColorSettings

## Currently enabled domain names for filtering
@export var enabled_domains: Array[String] = []

## All domain names discovered during runtime (persisted for next session)
@export var all_known_domains: Array[String] = []

## Console window screen position (-1, -1 means use default centering)
@export var window_position: Vector2i = Vector2i(-1, -1)

## Console window size in pixels
@export var window_size: Vector2i = Vector2i(DEFAULT_WINDOW_WIDTH, DEFAULT_WINDOW_HEIGHT)

## Whether console is currently minimized
@export var is_minimized: bool = false

## Whether console window is visible
@export var is_visible: bool = true

## Display/screen index where console was last positioned (-1 means primary display)
@export var display_index: int = -1

## Whether subwindows were embedded when settings were last saved
@export var was_embedded_subwindows: bool = false

## Current log level filter (stored as int for persistence)
@export var log_level: int = 4  # LoggieEnums.LogLevel.DEBUG

## Whether to auto-scroll to newest messages
@export var scroll_follow_enabled: bool = true

## Current text search filter term
@export var search_text: String = ""

## Whether to show only messages with stack traces
@export var stack_filter_enabled: bool = false

## Maximum number of messages to keep in buffer before cleanup
@export var max_messages: int = 5000

## Text size multiplier for console fonts (0.5 to 2.0, default 1.0)
@export var text_size_multiplier: float = 1.0

## Restore button alignment position (0=TOP_LEFT, 1=TOP_RIGHT, 2=BOTTOM_LEFT, 3=BOTTOM_RIGHT)
@export var restore_button_alignment: int = 1  # Default to TOP_RIGHT

## Settings file format version for future migration compatibility
@export var version: int = 1

## Unix timestamp when settings were last saved
@export var last_saved: float = 0.0

## Initializes default settings values
##
## Creates the filter state resource if it doesn't exist. This ensures that
## all required sub-resources are properly initialized even when creating
## settings from scratch.
func _init() -> void:
	if not filter_state:
		filter_state = LoggieConsoleFilterState.new()
	if not color_settings:
		color_settings = LoggieConsoleColorSettings.new()

## Validates and sanitizes all data after loading from disk
## Ensures all fields have valid values even if the saved file was corrupted
func validate() -> void:
	# Ensure filter state exists and is valid
	if not filter_state:
		filter_state = LoggieConsoleFilterState.new()
	filter_state.validate()
	
	# Ensure color settings exist and are valid
	if not color_settings:
		color_settings = LoggieConsoleColorSettings.new()
	color_settings.validate()
	
	# Ensure domain arrays exist
	if enabled_domains == null:
		enabled_domains = []
	if all_known_domains == null:
		all_known_domains = []
	
	# Validate log level is within enum range
	if log_level < 0 or log_level >= LoggieEnums.LogLevel.size():
		log_level = LoggieEnums.LogLevel.DEBUG
		Loggie.msg("Invalid log level, reset to DEBUG").domain(LoggieConsoleConstants.DOMAIN).warn()
	
	# Enforce minimum and maximum window size for usability
	_validate_window_size()
	
	# Ensure search text is never null
	if search_text == null:
		search_text = ""
	
	# Validate text size multiplier is within reasonable bounds
	if text_size_multiplier < 0.5 or text_size_multiplier > 2.0:
		text_size_multiplier = 1.0
		Loggie.msg("Invalid text size multiplier, reset to 1.0").domain(LoggieConsoleConstants.DOMAIN).warn()
	
	# Validate restore button alignment is within enum range (0-3)
	if restore_button_alignment < 0 or restore_button_alignment > 3:
		restore_button_alignment = 1  # Default to TOP_RIGHT
		Loggie.msg("Invalid restore button alignment, reset to TOP_RIGHT").domain(LoggieConsoleConstants.DOMAIN).warn()
	
	# Update save timestamp
	last_saved = Time.get_unix_time_from_system()

## Validates and ensures window size fits within available screen space
##
## Enforces minimum size for usability (400x300) and maximum size based on 
## screen dimensions. Checks all connected displays to find the largest
## available space and clamps the window size accordingly.
func _validate_window_size() -> void:
	# Get the largest available screen to determine maximum constraints
	var max_screen_size: Vector2i = Vector2i.ZERO
	var screens: int = DisplayServer.get_screen_count()
	
	for i: int in screens:
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(i)
		max_screen_size.x = maxi(max_screen_size.x, screen_rect.size.x)
		max_screen_size.y = maxi(max_screen_size.y, screen_rect.size.y)
	
	# Fallback if no screens detected
	if max_screen_size == Vector2i.ZERO:
		max_screen_size = Vector2i(1920, 1080)
	
	# Enforce minimum window size for usability
	window_size.x = maxi(window_size.x, MIN_WINDOW_WIDTH)
	window_size.y = maxi(window_size.y, MIN_WINDOW_HEIGHT)
	
	# Enforce maximum window size to fit on screen (with margins)
	var max_width: int = max_screen_size.x - SCREEN_MARGIN_PIXELS
	var max_height: int = max_screen_size.y - SCREEN_MARGIN_PIXELS
	
	if window_size.x > max_width:
		window_size.x = max_width
		Loggie.msg("Window width too large, clamped to %d" % max_width).domain(LoggieConsoleConstants.DOMAIN).warn()
	
	if window_size.y > max_height:
		window_size.y = max_height
		Loggie.msg("Window height too large, clamped to %d" % max_height).domain(LoggieConsoleConstants.DOMAIN).warn()

## Detects if embed_subwindows setting has changed since last save
## Returns: true if setting has changed and window positioning needs reset
func _has_embed_setting_changed() -> bool:
	var current_embedded = ProjectSettings.get_setting("display/window/subwindows/embed_subwindows", true)
	return current_embedded != was_embedded_subwindows

## Updates the stored embed_subwindows setting to current project setting
##
## This should be called whenever settings are saved to track the current
## embed_subwindows state for future change detection.
func update_embed_setting() -> void:
	was_embedded_subwindows = ProjectSettings.get_setting("display/window/subwindows/embed_subwindows", true)

## Validates and corrects window position for current display setup
## Returns: A valid window position that will be visible on screen
func validate_window_position() -> Vector2i:
	# Check if embed_subwindows setting has changed
	var embed_changed = _has_embed_setting_changed()
	var current_embedded = ProjectSettings.get_setting("display/window/subwindows/embed_subwindows", true)
	
	# If embed setting changed and window was previously invisible, reset position
	if embed_changed and not is_visible:
		Loggie.msg("embed_subwindows changed from %s to %s, resetting window position" % [was_embedded_subwindows, current_embedded]).domain(LoggieConsoleConstants.DOMAIN).warn()
		update_embed_setting()
		# Reset to default centering
		var target_display = _get_target_display()
		var target_rect: Rect2i = DisplayServer.screen_get_usable_rect(target_display)
		window_position = Vector2i(-1, -1)  # Mark for centering
		display_index = target_display
		return _center_window_on_screen(target_rect)
	
	# Update embed setting for future comparisons
	update_embed_setting()
	
	# Use default centering if position is not set
	if window_position == Vector2i(-1, -1):
		var target_display = _get_target_display()
		var target_rect: Rect2i = DisplayServer.screen_get_usable_rect(target_display)
		return _center_window_on_screen(target_rect)
	
	# If we have a specific display preference, validate against it first
	if display_index >= 0 and display_index < DisplayServer.get_screen_count():
		var preferred_rect: Rect2i = DisplayServer.screen_get_usable_rect(display_index)
		var validated_pos = _clamp_window_to_screen(window_position, preferred_rect)
		if validated_pos != window_position:
			Loggie.msg("Window position adjusted to fit display %d" % display_index).domain(LoggieConsoleConstants.DOMAIN).warn()
		return validated_pos
	
	# Check if window can fit properly on any connected display
	var screens: int = DisplayServer.get_screen_count()
	var best_display: int = -1
	var best_pos: Vector2i = window_position
	
	for i: int in screens:
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(i)
		var window_rect: Rect2i = Rect2i(window_position, window_size)
		
		# Check if window intersects with this screen
		if screen_rect.intersects(window_rect):
			best_display = i
			best_pos = _clamp_window_to_screen(window_position, screen_rect)
			# If the window fits perfectly on this screen, use it
			if best_pos == window_position:
				display_index = i
				return window_position
			break
	
	# If we found a suitable display, use the clamped position
	if best_display >= 0:
		display_index = best_display
		if best_pos != window_position:
			Loggie.msg("Window position clamped to fit display %d" % best_display).domain(LoggieConsoleConstants.DOMAIN).warn()
		return best_pos
	
	# Window is completely off-screen, center it on target display
	var target_display = _get_target_display()
	var target_rect: Rect2i = DisplayServer.screen_get_usable_rect(target_display)
	display_index = target_display
	Loggie.msg("Window position off-screen, centering on display %d" % target_display).domain(LoggieConsoleConstants.DOMAIN).warn()
	return _center_window_on_screen(target_rect)

## Centers the window on the given screen rectangle with margins
##
## Calculates a centered position that keeps the window fully visible with
## appropriate margins from screen edges.
## @param screen_rect: The target screen's usable rectangle
## @return: Position that centers the window with 20px margins
func _center_window_on_screen(screen_rect: Rect2i) -> Vector2i:
	var margin_vector: Vector2i = Vector2i(WINDOW_EDGE_MARGIN, WINDOW_EDGE_MARGIN)
	var available_size: Vector2i = screen_rect.size - margin_vector * 2
	var centered_offset: Vector2i = (available_size - window_size) / 2
	return screen_rect.position + margin_vector + centered_offset

## Clamps window position to ensure it fits entirely within screen bounds
##
## Adjusts the position to keep the entire window visible on the screen,
## respecting minimum margins from edges.
## @param pos: The desired window position
## @param screen_rect: The target screen's rectangle
## @return: Adjusted position that keeps the entire window visible
func _clamp_window_to_screen(pos: Vector2i, screen_rect: Rect2i) -> Vector2i:
	var margin: Vector2i = Vector2i(WINDOW_MIN_MARGIN, WINDOW_MIN_MARGIN)
	var usable_rect: Rect2i = Rect2i(
		screen_rect.position + margin,
		screen_rect.size - margin * 2
	)
	
	# Ensure window fits within usable area
	var max_pos: Vector2i = usable_rect.position + usable_rect.size - window_size
	
	var clamped_pos: Vector2i = Vector2i(
		clampi(pos.x, usable_rect.position.x, max_pos.x),
		clampi(pos.y, usable_rect.position.y, max_pos.y)
	)
	
	return clamped_pos

## Gets the target display index for window positioning
## Returns: Valid display index (0 if saved display no longer exists)
func _get_target_display() -> int:
	# Use saved display if it still exists
	if display_index >= 0 and display_index < DisplayServer.get_screen_count():
		return display_index
	
	# Fall back to primary display (index 0)
	return 0

## Gets the log level as a proper enum value
## Returns: The current log level as LoggieEnums.LogLevel
func get_log_level() -> LoggieEnums.LogLevel:
	return log_level as LoggieEnums.LogLevel

## Sets the log level from an enum value
## @param level: The new log level to store
func set_log_level(level: LoggieEnums.LogLevel) -> void:
	log_level = level as int
