@tool
class_name DomainItem extends Control

## Custom control for individual domain rows in PanelDomainSelector
## Provides checkbox selection, domain label, and hover-revealed "Only" button

const DomainColorManager = preload("res://addons/loggie-console/scripts/domain_color_manager.gd")

# Signals
signal selection_changed(domain_name: String, is_selected: bool)
signal only_button_pressed(domain_name: String)

# UI Components - exported for scene tree assignment
@export var select_checkbox: CheckBox
@export var only_button: Button
@export var color_indicator: ColorRect

# Domain state
var _domain_name: String = ""
var _is_hovered: bool = false
var _color_manager: DomainColorManager

# UI Layout constants
const ITEM_MIN_WIDTH: int = 280
const ITEM_MIN_HEIGHT: int = 32

# Visibility constants for only button hover effect
const ONLY_BUTTON_ALPHA_HIDDEN: float = 0.0
const ONLY_BUTTON_ALPHA_VISIBLE: float = 1.0

## Initializes the domain item control with UI connections and hover behavior
##
## Sets up consistent sizing, signal connections for checkbox and button interactions,
## and configures mouse hover detection for the "Only" button visibility toggle.
## The only button starts hidden and becomes visible on hover with smooth alpha transition.
## Requires select_checkbox and only_button to be properly assigned via @export.
func _ready() -> void:
	if not select_checkbox:
		return
		
	# Set minimum size for consistent layout
	custom_minimum_size = Vector2(ITEM_MIN_WIDTH, ITEM_MIN_HEIGHT)
	
	# Connect signals
	select_checkbox.toggled.connect(_on_checkbox_toggled)
	only_button.pressed.connect(_on_only_button_pressed)
	
	# Setup hover detection on checkbox (which now contains the text)
	select_checkbox.mouse_entered.connect(_on_mouse_entered)
	select_checkbox.mouse_exited.connect(_on_mouse_exited)
	
	# Also setup hover detection on the main control for complete coverage
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	
	# Initialize only button as hidden
	only_button.modulate.a = ONLY_BUTTON_ALPHA_HIDDEN
	only_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Set the domain color manager instance
func set_color_manager(color_manager: DomainColorManager) -> void:
	_color_manager = color_manager

## Configures the domain item with a specific domain name and selection state
##
## Sets up the checkbox display text (shows "(default)" for empty domain names),
## configures tooltips for both checkbox and only button, and applies the initial
## selection state. This method should be called after the item is added to the scene tree.
##
## @param domain_name: The domain name to display and track
## @param is_selected: Whether the domain should start as selected
func setup_domain(domain_name: String, is_selected: bool = false) -> void:
	_domain_name = domain_name
	
	if select_checkbox:
		var display_name = domain_name if not domain_name.is_empty() else "(default)"
		
		# Update color indicator instead of modulating checkbox
		if _color_manager and color_indicator:
			var domain_color = _color_manager.get_domain_color(domain_name)
			color_indicator.color = domain_color
		
		select_checkbox.text = display_name
		select_checkbox.tooltip_text = "Select/deselect domain: " + domain_name
		select_checkbox.button_pressed = is_selected
	
	if only_button:
		only_button.text = "Only"
		only_button.tooltip_text = "Select only this domain: " + domain_name

## Get the domain name for this item
func get_domain_name() -> String:
	return _domain_name

## Updates the checkbox selection state without emitting signals
##
## Useful for programmatically setting the selection state during bulk operations
## like "Select All" or when loading from saved settings. Uses set_pressed_no_signal
## to avoid triggering selection_changed signals during these operations.
##
## @param is_selected: The new selection state for the checkbox
func set_selected(is_selected: bool) -> void:
	if select_checkbox:
		select_checkbox.set_pressed_no_signal(is_selected)

## Get current selection state
func is_selected() -> bool:
	return select_checkbox.button_pressed if select_checkbox else false

## Private methods

func _on_checkbox_toggled(pressed: bool) -> void:
	selection_changed.emit(_domain_name, pressed)

func _on_only_button_pressed() -> void:
	only_button_pressed.emit(_domain_name)


func _on_mouse_entered() -> void:
	_is_hovered = true
	_set_only_button_visibility(true)

func _on_mouse_exited() -> void:
	_is_hovered = false
	_set_only_button_visibility(false)

## Controls the visibility and interaction of the "Only" button based on hover state
##
## Instantly toggles the button's alpha transparency and mouse filter to create
## a hover-reveal effect. When hidden, the button becomes completely transparent
## and ignores mouse input. When visible, it becomes fully opaque and interactive.
##
## @param show: Whether to show (true) or hide (false) the only button
func _set_only_button_visibility(show: bool) -> void:
	if not only_button:
		return
	
	# Set visibility instantly - no animation
	var target_alpha = ONLY_BUTTON_ALPHA_VISIBLE if show else ONLY_BUTTON_ALPHA_HIDDEN
	var target_mouse_filter = Control.MOUSE_FILTER_PASS if show else Control.MOUSE_FILTER_IGNORE
	
	only_button.modulate.a = target_alpha
	only_button.mouse_filter = target_mouse_filter

func _gui_input(event: InputEvent) -> void:
	# Handle keyboard navigation
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				if select_checkbox:
					select_checkbox.button_pressed = not select_checkbox.button_pressed
					_on_checkbox_toggled(select_checkbox.button_pressed)
				accept_event()
			KEY_O:
				if event.ctrl_pressed:  # Ctrl+O for "Only"
					_on_only_button_pressed()
					accept_event()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_FOCUS_ENTER:
			# Add visual focus indication if needed
			pass
		NOTIFICATION_FOCUS_EXIT:
			# Remove visual focus indication if needed
			pass
