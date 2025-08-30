@tool  
class_name ConsoleControls extends HBoxContainer

## Console controls toolbar component
## Manages clear button, scroll follow, and other control elements

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")

# Signals
signal clear_requested()
signal scroll_follow_changed(enabled: bool)
signal text_search_changed(search_text: String)
signal stack_filter_changed(enabled: bool)

# Exported references to child controls
@export var clear_button: Button
@export var scroll_follow_checkbox: CheckBox
@export var search_input: LineEdit
@export var stack_filter_checkbox: CheckBox

func _ready() -> void:
	_setup_controls()

## Initialize the controls with default states
func initialize() -> void:
	if scroll_follow_checkbox:
		scroll_follow_checkbox.button_pressed = true
		_on_scroll_follow_toggled(true)

## Get current scroll follow state
func is_scroll_follow_enabled() -> bool:
	return scroll_follow_checkbox.button_pressed if scroll_follow_checkbox else false

## Set scroll follow state programmatically
func set_scroll_follow(enabled: bool) -> void:
	if scroll_follow_checkbox:
		scroll_follow_checkbox.button_pressed = enabled

## Get current text search
func get_search_text() -> String:
	return search_input.text if search_input else ""

## Set search text programmatically
func set_search_text(text: String) -> void:
	if search_input:
		search_input.text = text

## Get current stack filter state
func is_stack_filter_enabled() -> bool:
	return stack_filter_checkbox.button_pressed if stack_filter_checkbox else false

## Set stack filter state programmatically
func set_stack_filter(enabled: bool) -> void:
	if stack_filter_checkbox:
		stack_filter_checkbox.button_pressed = enabled

## Private methods

func _setup_controls() -> void:
	# Connect clear button if available
	if clear_button:
		clear_button.pressed.connect(_on_clear_pressed)
		clear_button.tooltip_text = "Clear console buffer"
	
	# Connect scroll follow checkbox if available
	if scroll_follow_checkbox:
		scroll_follow_checkbox.toggled.connect(_on_scroll_follow_toggled)
		scroll_follow_checkbox.tooltip_text = "Auto-scroll to newest messages"
	
	# Connect search input if available
	if search_input:
		search_input.text_changed.connect(_on_search_text_changed)
		search_input.placeholder_text = "Filter messages..."
	
	# Connect stack filter checkbox if available
	if stack_filter_checkbox:
		stack_filter_checkbox.toggled.connect(_on_stack_filter_toggled)
		stack_filter_checkbox.tooltip_text = "Show only messages with stack traces"

func _on_clear_pressed() -> void:
	clear_requested.emit()

func _on_scroll_follow_toggled(enabled: bool) -> void:
	scroll_follow_changed.emit(enabled)

func _on_search_text_changed(new_text: String) -> void:
	text_search_changed.emit(new_text)

func _on_stack_filter_toggled(enabled: bool) -> void:
	stack_filter_changed.emit(enabled)

## Saves current toolbar control states to persistent settings
## Param settings: The settings resource to populate with current control states
func save_settings_to_resource(settings: LoggieConsoleSettings) -> void:
	settings.scroll_follow_enabled = is_scroll_follow_enabled()
	settings.search_text = get_search_text()
	settings.stack_filter_enabled = is_stack_filter_enabled()

## Loads toolbar control states from persistent settings and applies them
## Updates all UI controls to reflect the loaded state without emitting signals
## Param settings: The settings resource containing saved control states
func load_settings_from_resource(settings: LoggieConsoleSettings) -> void:
	set_scroll_follow(settings.scroll_follow_enabled)
	set_search_text(settings.search_text)
	set_stack_filter(settings.stack_filter_enabled)
