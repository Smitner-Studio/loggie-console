## Enhanced LoggieConsole with persistence, minimize/restore, and multi-display support
##
## This console window provides an advanced debugging interface for the Loggie logging system.
## Features include:
## - Persistent window positioning and settings across sessions
## - Multi-display awareness for non-embedded subwindows
## - Domain-based filtering with dynamic discovery
## - Minimize/restore functionality with floating restore button
## - Complete component-based architecture for extensibility
##
## The console automatically saves all settings when closed or minimized, and restores
## the exact previous state on next startup, including window position, size, filters,
## and discovered domains.
@tool
class_name LoggieConsole extends Window

# Constants
const LoggieConsoleChannel = preload("res://addons/loggie-console/scripts/loggie_console_channel.gd")
const ConsoleSettingsManager = preload("res://addons/loggie-console/scripts/managers/console_settings_manager.gd")
const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")
const RestoreButtonScene := preload("res://addons/loggie-console/scenes/restore_button.tscn")
const DomainColorManager = preload("res://addons/loggie-console/scripts/domain_color_manager.gd")


# UI Constants
const WINDOW_MARGIN_PIXELS: int = 5

# Display detection constants
const DEFAULT_DOMAIN_OFFSET: int = 1  # +1 for default domain in total domain count


# Exported component references - automatically assigned from scene
@export var buffer: LogBuffer ## Log message display and filtering component
@export var output_level: LogLevelFilter ## Log level selection component  
@export var domain_filter: PanelDomainSelector ## Domain multi-selection component
@export var controls: ConsoleControls ## Control buttons and settings component
@export var status_display: StatusDisplay ## Status and statistics display component

# Settings UI references
var _settings_button: Button ## Settings button in controls
var _settings_panel: LoggieConsoleSettingsPanel ## Settings panel component


# Minimize/restore system state
var _restore_button_component: RestoreButton ## Restore button component instance
var _is_minimized: bool = false ## Current minimized state

# Custom Loggie channel for receiving log messages
var _console_channel: LoggieConsoleChannel ## Direct channel integration with Loggie

# Component coordination
var _filter_state: LogBuffer.FilterState ## Shared filter state between components

# Persistence system
var _settings_manager: ConsoleSettingsManager ## Handles save/load operations
var _current_settings: LoggieConsoleSettings ## Current settings instance

# Domain color management
var _domain_color_manager: DomainColorManager ## Centralized color management for all components

## Initializes the console window and all its components
##
## This is the main initialization sequence that:
## 1. Loads persistent settings from disk
## 2. Applies window positioning and visibility settings
## 3. Initializes all components with loaded state
## 4. Sets up the custom Loggie channel for message reception
## 5. Connects all necessary signals for runtime operation
##
## The order is critical - settings must be loaded and applied before
## components are initialized to prevent unwanted signal emissions during startup.
func _ready() -> void:
	# Initialize persistence system FIRST
	_settings_manager = ConsoleSettingsManager.new()
	_current_settings = _settings_manager.load_settings()
	
	_restore_button_component = RestoreButtonScene.instantiate()
	_restore_button_component.restore_requested.connect(_on_restore_requested)
	
	# Apply window settings before component initialization
	_apply_window_settings()
	
	# Connect window signals for persistence
	close_requested.connect(_on_close_requested)
	
	# Initialize components with loaded settings
	_initialize_components()
	
	# Setup save triggers after initialization
	_setup_save_triggers()
	
	# Setup custom channel
	_setup_console_channel()
	
	# Apply loaded filters after components are ready
	_apply_loaded_settings()

## Called by our custom LoggieConsoleChannel with complete message data
##
## This is the main message reception callback that receives log messages directly
## from the Loggie system through our custom channel. Unlike signal-based approaches,
## this provides complete type information including LogLevel and MsgType enums.
##
## @param msg: The original LoggieMsg with all metadata
## @param preprocessed_content: Fully formatted message text from Loggie
## @param msg_type: Message type enum (ERROR, WARNING, DEBUG, STANDARD)
## @param log_level: Log level enum (ERROR, WARN, NOTICE, INFO, DEBUG)
func receive_log_message(msg: LoggieMsg, preprocessed_content: String, msg_type: LoggieEnums.MsgType, log_level: LoggieEnums.LogLevel) -> void:
	# Check if we need to add a new domain to our list
	if not msg.domain_name.is_empty():
		domain_filter.add_domain(msg.domain_name)
	
	# Add message to buffer (buffer handles filtering internally)
	buffer.add_message(msg, preprocessed_content, msg_type, log_level)

## Sets up the custom Loggie channel for direct message reception
##
## Creates and registers a LoggieConsoleChannel that provides the console with
## direct access to log messages including complete type information. The channel
## is automatically added to the default channels list so it receives all messages
## by default, without requiring explicit channel targeting in log calls.
func _setup_console_channel() -> void:
	# Create and register our custom channel
	_console_channel = LoggieConsoleChannel.new()
	_console_channel.set_console_window(self)
	Loggie.add_channel(_console_channel)
	
	# Automatically add our channel to the default channels so console receives all messages
	var current_defaults: Array = Loggie.settings.default_channels
	if not current_defaults.has("loggie_console"):
		var new_defaults: Array = current_defaults.duplicate()
		new_defaults.append("loggie_console")
		Loggie.settings.default_channels = new_defaults

func _setup_domain_filter() -> void:
	# Get all domains dynamically from Loggie
	var initial_domains: Array[String] = [""]  # Always include default domain
	
	# Get all registered domains from Loggie
	for domain_name: String in Loggie.domains.keys():
		if not initial_domains.has(domain_name):
			initial_domains.append(domain_name)
	
	# Add LoggieConsole internal domain (will appear unselected by default)
	if not initial_domains.has(LoggieConsoleConstants.DOMAIN):
		var all_domains: Array[String] = initial_domains.duplicate()
		all_domains.append(LoggieConsoleConstants.DOMAIN)
		
		# Initialize the domain selector with all domains (including console domain)
		domain_filter.set_domains_with_console_unselected(all_domains, initial_domains, [LoggieConsoleConstants.DOMAIN])
	else:
		# Console domain already exists, use standard initialization
		domain_filter.set_domains(initial_domains)
	domain_filter.domains_changed.connect(_on_domains_changed)
	
	# Apply initial filter state to buffer (only enabled domains, not internal ones)
	_filter_state.enabled_domains = initial_domains
	buffer.set_filters(_filter_state)

func _on_domains_changed(enabled_domains: Array[String]) -> void:
	# Update filter state and apply to buffer
	_filter_state.enabled_domains = enabled_domains
	buffer.set_filters(_filter_state)




## New component event handlers

func _on_log_level_changed(new_level: LoggieEnums.LogLevel) -> void:
	# Update filter state and apply to buffer
	_filter_state.min_log_level = new_level
	buffer.set_filters(_filter_state)

func _on_clear_requested() -> void:
	# Clear the buffer
	buffer.clear_all()

func _on_scroll_follow_changed(enabled: bool) -> void:
	# Update buffer scroll following
	buffer.scroll_following = enabled

func _on_text_search_changed(search_text: String) -> void:
	# Update filter state and apply to buffer
	_filter_state.text_search = search_text
	buffer.set_filters(_filter_state)

func _on_stack_filter_changed(enabled: bool) -> void:
	# Update filter state and apply to buffer
	_filter_state.show_stack_only = enabled
	buffer.set_filters(_filter_state)

func _on_buffer_filter_changed(visible_count: int, total_count: int) -> void:
	# Update status display with current counts
	var enabled_domains: Array[String] = domain_filter.get_enabled_domains()
	var total_domains: int = enabled_domains.size()
	if total_domains == 0:
		total_domains = Loggie.domains.keys().size() + DEFAULT_DOMAIN_OFFSET
	
	status_display.update_status(total_count, visible_count, enabled_domains, total_domains)


## Minimize/Restore System


## Minimizes the console window and shows a floating restore button
##
## This hides the console window and creates a small floating "LOG" button in the
## top-right corner of the main viewport. The button allows restoring the console
## to its previous position and size. All settings are saved before minimizing
## to ensure state persistence.
func minimize_console() -> void:
	if _is_minimized:
		Loggie.msg("Already minimized, ignoring request").domain(LoggieConsoleConstants.DOMAIN).warn()
		return
	
	# Save current settings including window state before minimizing
	_capture_current_state()
	_settings_manager.save_settings(_current_settings)
	
	_is_minimized = true
	hide()  # Hide the console window
	_show_restore_button()

## Creates and shows the restore button component
##
## Instantiates the RestoreButton scene and displays it in the root viewport.
## Connects the restore_requested signal to handle button clicks and restore the console.
func _show_restore_button() -> void:
	_restore_button_component.show_restore_button(get_tree().root)
	Loggie.msg("RestoreButton show_restore_button() called").domain(LoggieConsoleConstants.DOMAIN).debug()

## Handles restore button click events from the RestoreButton component
##
## Called when the RestoreButton component emits its restore_requested signal.
## Triggers the console restoration process.
func _on_restore_requested() -> void:
	restore_console()

## Restores the console window from minimized state
##
## This shows the console window at its previously saved position and size,
## removes the floating restore button, and updates the minimized state.
## The window is restored exactly as it was when minimized.
func restore_console() -> void:
	if not _is_minimized:
		Loggie.msg("Not minimized, ignoring restore request").domain(LoggieConsoleConstants.DOMAIN).warn()
		return
	
	# Restore to saved position and size from settings
	position = _current_settings.window_position
	size = _current_settings.window_size
	
	_is_minimized = false
	show()  # Show the console window
	_hide_restore_button()

## Hides and cleans up the restore button component
##
## Removes the RestoreButton component from the scene tree and frees its resources.
## Ensures proper cleanup when the console is restored from minimized state.
func _hide_restore_button() -> void:
	if _restore_button_component and is_instance_valid(_restore_button_component):
		_restore_button_component.hide_restore_button()
		Loggie.msg("Restore button component cleaned up").domain(LoggieConsoleConstants.DOMAIN).debug()

## Applies saved window properties to the console window
## Validates position to ensure window remains visible on current display setup
func _apply_window_settings() -> void:
	# Check if we're using embedded subwindows
	var subwindows_embedded: bool = ProjectSettings.get_setting("display/window/subwindows/embed_subwindows", true)
	
	var validated_pos: Vector2i
	if subwindows_embedded and _is_outside_viewport():
		validated_pos = _center_window()
	else:
		# Use existing validation for separate windows or valid embedded positions
		validated_pos = _current_settings.validate_window_position()
	
	position = validated_pos
	
	# Apply saved window dimensions
	size = _current_settings.window_size
	
	# Apply visibility state
	visible = _current_settings.is_visible
	
	# Apply minimized state (defer restore button creation)
	_is_minimized = _current_settings.is_minimized
	if _is_minimized:
		hide()
		# Defer restore button creation until scene tree is ready
		_show_restore_button.call_deferred()

## Checks if console window is outside the main viewport (for embedded subwindows)
func _is_outside_viewport() -> bool:
	var viewport_size: Vector2i = Vector2i(get_tree().root.get_visible_rect().size)
	var window_rect: Rect2i = Rect2i(_current_settings.window_position, _current_settings.window_size)
	var viewport_rect: Rect2i = Rect2i(Vector2i.ZERO, viewport_size)
	
	# Return true if window is not completely within viewport or has invalid position
	return _current_settings.window_position == Vector2i(-1, -1) or not viewport_rect.encloses(window_rect)

## Centers the console window in the main viewport
func _center_window() -> Vector2i:
	var viewport_size: Vector2i = Vector2i(get_tree().root.get_visible_rect().size)
	const MARGIN = 50
	var centered_pos: Vector2i = (viewport_size - _current_settings.window_size) / 2
	return Vector2i(maxi(MARGIN, centered_pos.x), maxi(MARGIN, centered_pos.y))

## Initializes all console components with loaded settings before connecting signals
## This prevents unwanted signal emissions during the initialization process
func _initialize_components() -> void:
	# Initialize base filter state
	_filter_state = LogBuffer.FilterState.new()
	
	# Create domain color manager
	_domain_color_manager = DomainColorManager.new()
	
	# Pass color manager to components that need it
	buffer.set_color_manager(_domain_color_manager)
	domain_filter.set_color_manager(_domain_color_manager)
	
	# Load persistent settings into each component
	buffer.load_settings_from_resource(_current_settings)
	domain_filter.load_settings_from_resource(_current_settings)
	controls.load_settings_from_resource(_current_settings)
	output_level.load_settings_from_resource(_current_settings)
	
	# Connect component signals for runtime interaction
	output_level.level_changed.connect(_on_log_level_changed)
	controls.clear_requested.connect(_on_clear_requested)
	controls.scroll_follow_changed.connect(_on_scroll_follow_changed)
	controls.text_search_changed.connect(_on_text_search_changed)
	controls.stack_filter_changed.connect(_on_stack_filter_changed)
	
	# Configure buffer with loaded scroll following setting
	buffer.filter_changed.connect(_on_buffer_filter_changed)
	buffer.scroll_following = controls.is_scroll_follow_enabled()
	
	# Set up remaining console systems
	_setup_domain_filter()
	
	# Initialize settings UI
	_setup_settings_ui()
	status_display.reset()

## Finalizes the loading process by applying loaded filter settings
## Called after component initialization to ensure filters work with existing messages
func _apply_loaded_settings() -> void:
	# Apply the loaded filter state to any existing messages
	buffer.apply_loaded_filters()
	
	# Sync domain filter state to ensure consistency
	domain_filter.domains_changed.emit(domain_filter.get_enabled_domains())
	
	# Apply text size setting to theme
	_apply_text_size_to_theme(_current_settings.text_size_multiplier)
	
	# Apply restore button alignment
	_apply_restore_button_alignment(_current_settings.restore_button_alignment)

## Placeholder for save triggers (not used in exit-tree persistence model)
func _setup_save_triggers() -> void:
	pass  # Settings saved only on exit tree

## Captures current state from window and all components into the settings resource
## This is called before each save operation to ensure all current state is preserved
func _capture_current_state() -> void:
	# Capture window properties
	_current_settings.window_position = position
	_current_settings.window_size = size
	_current_settings.is_visible = visible
	_current_settings.is_minimized = _is_minimized
	
	# Capture current display index (important when embed_subwindows=false)
	_current_settings.display_index = _get_current_display_index()
	
	# Capture current embed_subwindows setting for change detection
	_current_settings.update_embed_setting()
	
	# Let each component save its own state
	buffer.save_settings_to_resource(_current_settings)
	domain_filter.save_settings_to_resource(_current_settings)
	controls.save_settings_to_resource(_current_settings)
	output_level.save_settings_to_resource(_current_settings)

## Manually saves current console settings to disk
## Useful for forcing a save before potentially destructive operations
func save_settings() -> void:
	_capture_current_state()
	_settings_manager.save_settings(_current_settings)

## Handles window close requests by saving settings first, then minimizing
## This ensures settings are preserved even if the console is closed unexpectedly
func _on_close_requested() -> void:
	# Preserve settings before minimizing
	_capture_current_state()
	_settings_manager.save_settings(_current_settings)
	
	# Continue with normal minimize behavior
	minimize_console()

## Automatically saves settings when console exits the scene tree
## This is the primary save mechanism ensuring settings persist between sessions
func _exit_tree() -> void:
	if _settings_manager and _current_settings:
		_capture_current_state()
		_settings_manager.save_settings(_current_settings)

## Handles system-level window destruction notifications
## Provides additional safety net for settings preservation
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _settings_manager and _current_settings:
			_capture_current_state()
			_settings_manager.save_settings(_current_settings)

## Determines which display the console window is currently on
## Returns: Display index (0-based) where the window center is located
func _get_current_display_index() -> int:
	# Calculate window center point
	var window_center: Vector2i = position + size / 2
	
	# Check which display contains the window center
	var screens: int = DisplayServer.get_screen_count()
	for i: int in screens:
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(i)
		if screen_rect.has_point(window_center):
			return i
	
	# Fallback: find display with most window overlap
	var max_overlap: int = 0
	var best_display: int = 0
	var window_rect: Rect2i = Rect2i(position, size)
	
	for i: int in screens:
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect(i)
		var intersection: Rect2i = screen_rect.intersection(window_rect)
		var overlap_area: int = intersection.size.x * intersection.size.y
		if overlap_area > max_overlap:
			max_overlap = overlap_area
			best_display = i
	
	return best_display

## Sets up the settings UI components and connects their signals
##
## Initializes the settings button and panel component, loads current settings,
## and connects the component's signals for handling settings changes.
func _setup_settings_ui() -> void:
	# Get UI component references
	_settings_button = get_node("PanelContainer/VBoxContainer/Controls/Settings")
	_settings_panel = get_node("SettingsPanel")
	
	# Connect signals
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_settings_panel.settings_applied.connect(_on_settings_applied)
	_settings_panel.settings_reset.connect(_on_settings_reset)
	
	# Load current settings into the panel
	_settings_panel.set_text_size_multiplier(_current_settings.text_size_multiplier)
	_settings_panel.set_restore_button_alignment(_current_settings.restore_button_alignment)

## Called when the Settings button is pressed
##
## Shows the settings panel dialog with current values loaded.
func _on_settings_button_pressed() -> void:
	_settings_panel.show_settings()

## Called when settings are applied via the settings panel
##
## Saves the new settings and applies them dynamically.
## @param text_size_multiplier: The new text size multiplier value
## @param restore_button_alignment: The new restore button alignment
func _on_settings_applied(text_size_multiplier: float, restore_button_alignment: RestoreButton.Alignment) -> void:
	# Update settings
	_current_settings.text_size_multiplier = text_size_multiplier
	_current_settings.restore_button_alignment = restore_button_alignment as int
	_settings_manager.save_settings(_current_settings)
	
	# Apply text size change to theme
	_apply_text_size_to_theme(text_size_multiplier)
	
	# Apply restore button alignment
	_apply_restore_button_alignment(restore_button_alignment as int)
	
	Loggie.msg("Settings updated: text size %.1fx, alignment %s" % [text_size_multiplier, _get_alignment_name(restore_button_alignment)]).domain(LoggieConsoleConstants.DOMAIN).info()

## Called when the settings are reset to defaults
##
## Logs the reset action for user feedback.
func _on_settings_reset() -> void:
	Loggie.msg("Settings reset to defaults").domain(LoggieConsoleConstants.DOMAIN).info()

## Dynamically applies text size multiplier to the current theme
##
## Modifies font sizes in the theme resource at runtime to immediately
## reflect the new text size setting without requiring a restart.
## @param multiplier: Text size multiplier (0.5 to 2.0)
func _apply_text_size_to_theme(multiplier: float) -> void:
	var console_theme: Theme = get_theme()
	if not console_theme:
		Loggie.msg("No theme found, cannot apply text size").domain(LoggieConsoleConstants.DOMAIN).error()
		return
	
	# Define base font sizes (from theme_compact.tres)
	var base_font_sizes: Dictionary = {
		"Button/font_size": 11,
		"CheckBox/font_size": 11,
		"LineEdit/font_size": 12,
		"MenuButton/font_size": 11,
		"OptionButton/font_size": 11,
		"PopupMenu/font_size": 11,
		"RichTextLabel/bold_font_size": 10,
		"RichTextLabel/bold_italics_font_size": 10,
		"RichTextLabel/italics_font_size": 10,
		"RichTextLabel/mono_font_size": 9,
		"RichTextLabel/normal_font_size": 10,
		"Window/title_font_size": 16
	}
	
	# Apply multiplier to each font size
	for font_path: String in base_font_sizes:
		var parts: PackedStringArray = font_path.split("/")
		var control_type: String = parts[0]
		var property: String = parts[1]
		var base_size: int = base_font_sizes[font_path]
		var new_size: int = int(base_size * multiplier)
		
		console_theme.set_font_size(property, control_type, new_size)
	
	# Theme changes are applied automatically

## Applies the restore button alignment setting
##
## Updates the restore button position based on the alignment preference.
## @param alignment: Alignment enum value (0=TOP_LEFT, 1=TOP_RIGHT, 2=BOTTOM_LEFT, 3=BOTTOM_RIGHT)
func _apply_restore_button_alignment(alignment: int) -> void:
	if not _restore_button_component:
		return
		
	# Set position based on alignment using the RestoreButton's enum
	var restore_alignment: RestoreButton.Alignment = alignment as RestoreButton.Alignment
	_restore_button_component.set_alignment(restore_alignment)

## Gets a human-readable name for the alignment enum
##
## @param alignment: The alignment enum value
## @return: String name of the alignment
func _get_alignment_name(alignment: RestoreButton.Alignment) -> String:
	match alignment:
		RestoreButton.Alignment.TOP_LEFT:
			return "Top Left"
		RestoreButton.Alignment.TOP_RIGHT:
			return "Top Right"
		RestoreButton.Alignment.BOTTOM_LEFT:
			return "Bottom Left"
		RestoreButton.Alignment.BOTTOM_RIGHT:
			return "Bottom Right"
		_:
			return "Unknown"

	
