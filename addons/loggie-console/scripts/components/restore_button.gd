@tool
class_name RestoreButton extends CanvasLayer

## Floating restore button component for minimized LoggieConsole
##
## Self-contained overlay button that appears when the console is minimized.
## Handles its own positioning, styling, and lifecycle management with proper
## cleanup when the console is restored. Designed to be added to the root viewport
## for maximum visibility across all scenes.

const LoggieConsoleConstants = preload("res://addons/loggie-console/scripts/loggie_console_constants.gd")

# Alignment constants
enum Alignment {
	TOP_LEFT = 0,
	TOP_RIGHT = 1,
	BOTTOM_LEFT = 2,
	BOTTOM_RIGHT = 3
}

# Signals
signal restore_requested() ## Emitted when user clicks the restore button
@export var restore_button: Button

## Initializes the restore button component and sets up styling
##
## Configures the canvas layer for maximum rendering priority, sets up the
## container to fill the viewport, and applies professional styling to the
## restore button. All UI components must be properly assigned via @export.
func _ready() -> void:
	Loggie.msg("RestoreButton _ready() called").domain(LoggieConsoleConstants.DOMAIN).debug()
	
	# Connect button signal
	restore_button.pressed.connect(_on_restore_button_pressed)
	
	Loggie.msg("RestoreButton initialization complete").domain(LoggieConsoleConstants.DOMAIN).debug()

## Shows the restore button by adding it to the provided scene tree root
##
## This method expects to be called from a parent that has access to the scene tree.
## The parent should pass the root viewport so this component can add itself properly.
##
## @param root_viewport: The root viewport where the button should be added
func show_restore_button(root_viewport: Window = null) -> void:
	Loggie.msg("RestoreButton show_restore_button() method called").domain(LoggieConsoleConstants.DOMAIN).debug()
	
	if not root_viewport:
		Loggie.msg("No root viewport available for restore button").domain(LoggieConsoleConstants.DOMAIN).error()
		return
	
	root_viewport.add_child(self)
	Loggie.msg("Restore button added to root viewport: %s" % root_viewport.name).domain(LoggieConsoleConstants.DOMAIN).debug()
	await get_tree().process_frame
	# Ensure visibility
	visible = true
	Loggie.msg("Restore button visibility set to true").domain(LoggieConsoleConstants.DOMAIN).debug()
	
	# Force positioning update and debug info
	await get_tree().process_frame

## Hides and removes the restore button from the scene tree
##
## Safely removes the button from its parent and hides it. Handles cleanup
## and ensures proper resource management when the console is restored.
func hide_restore_button() -> void:
	Loggie.msg("Hiding restore button").domain(LoggieConsoleConstants.DOMAIN).debug()
	
	visible = false
	
	# Remove from parent if attached
	if get_parent():
		get_parent().remove_child(self)
		Loggie.msg("Restore button removed from parent").domain(LoggieConsoleConstants.DOMAIN).debug()

## Sets the alignment position of the restore button
##
## Updates the button's position flags to align it to the specified corner of the screen.
## @param alignment: The alignment enum value (TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT)
func set_alignment(alignment: Alignment) -> void:
	if not restore_button:
		Loggie.msg("RestoreButton not found, cannot set alignment").domain(LoggieConsoleConstants.DOMAIN).warn()
		return
	
	match alignment:
		Alignment.TOP_LEFT:
			restore_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # 0 = left align
			restore_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN    # 0 = top align
		Alignment.TOP_RIGHT:
			restore_button.size_flags_horizontal = Control.SIZE_SHRINK_END     # 8 = right align
			restore_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN    # 0 = top align
		Alignment.BOTTOM_LEFT:
			restore_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # 0 = left align
			restore_button.size_flags_vertical = Control.SIZE_SHRINK_END       # 8 = bottom align
		Alignment.BOTTOM_RIGHT:
			restore_button.size_flags_horizontal = Control.SIZE_SHRINK_END     # 8 = right align
			restore_button.size_flags_vertical = Control.SIZE_SHRINK_END       # 8 = bottom align
	
	Loggie.msg("Restore button alignment set to: %s" % _get_alignment_name(alignment)).domain(LoggieConsoleConstants.DOMAIN).debug()

## Gets a human-readable name for the alignment enum
##
## @param alignment: The alignment enum value
## @return: String name of the alignment
func _get_alignment_name(alignment: Alignment) -> String:
	match alignment:
		Alignment.TOP_LEFT:
			return "Top Left"
		Alignment.TOP_RIGHT:
			return "Top Right"
		Alignment.BOTTOM_LEFT:
			return "Bottom Left"
		Alignment.BOTTOM_RIGHT:
			return "Bottom Right"
		_:
			return "Unknown"

## Handles restore button click events
##
## Emits the restore_requested signal when the button is pressed, allowing
## the parent console to handle the actual restore logic while keeping
## this component focused solely on UI concerns.
func _on_restore_button_pressed() -> void:
	Loggie.msg("Restore button pressed").domain(LoggieConsoleConstants.DOMAIN).debug()
	restore_requested.emit()
