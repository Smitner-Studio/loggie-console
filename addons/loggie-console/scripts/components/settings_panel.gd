class_name LoggieConsoleSettingsPanel extends AcceptDialog

## Standalone settings panel component for LoggieConsole
##
## This component provides a clean, reusable interface for adjusting console settings
## such as text size multiplier. It emits signals when settings are changed and provides
## methods to get/set current values.
##
## Signals:
## - settings_applied(text_size_multiplier: float): Emitted when Apply is clicked
## - settings_reset(): Emitted when Reset to Default is clicked
##
## Public Methods:
## - set_text_size_multiplier(value: float): Sets the current text size value
## - get_text_size_multiplier() -> float: Gets the current text size value
## - reset_to_defaults(): Resets all settings to default values

## Emitted when the user clicks Apply with current settings
signal settings_applied(text_size_multiplier: float, restore_button_alignment: RestoreButton.Alignment)

## Emitted when the user clicks Reset to Default
signal settings_reset()

# UI component references - assigned via editor
@export var _text_size_slider: HSlider
@export var _text_size_value_label: Label
@export var _reset_button: Button
@export var _alignment_option: OptionButton ## Optional - may be null in simplified versions

# Constants
const DEFAULT_TEXT_SIZE_MULTIPLIER: float = 1.0
const MIN_TEXT_SIZE_MULTIPLIER: float = 0.5
const MAX_TEXT_SIZE_MULTIPLIER: float = 2.0
const DEFAULT_RESTORE_BUTTON_ALIGNMENT: RestoreButton.Alignment = RestoreButton.Alignment.TOP_RIGHT

## Initializes the settings panel and connects internal signals
func _ready() -> void:
	# Connect internal UI signals
	_text_size_slider.value_changed.connect(_on_text_size_slider_changed)
	_reset_button.pressed.connect(_on_reset_button_pressed)
	confirmed.connect(_on_apply_pressed)
	
	# Initialize display
	_update_text_size_label(_text_size_slider.value)

## Sets the text size multiplier value
##
## Updates the slider position and display label to reflect the new value.
## The value is automatically clamped to the valid range (0.5 to 2.0).
##
## @param value: The text size multiplier (will be clamped to valid range)
func set_text_size_multiplier(value: float) -> void:
	var clamped_value: float = clampf(value, MIN_TEXT_SIZE_MULTIPLIER, MAX_TEXT_SIZE_MULTIPLIER)
	_text_size_slider.value = clamped_value
	_update_text_size_label(clamped_value)

## Gets the current text size multiplier value
##
## @return: The current text size multiplier value from the slider
func get_text_size_multiplier() -> float:
	return _text_size_slider.value

## Sets the restore button alignment
##
## Updates the alignment option button to reflect the new value.
## If the alignment option doesn't exist, the setting is ignored.
## @param alignment: The restore button alignment enum value
func set_restore_button_alignment(alignment: RestoreButton.Alignment) -> void:
	if _alignment_option:
		_alignment_option.selected = alignment as int

## Gets the current restore button alignment
##
## @return: The current restore button alignment as an enum value, or default if option doesn't exist
func get_restore_button_alignment() -> RestoreButton.Alignment:
	if _alignment_option:
		return _alignment_option.selected as RestoreButton.Alignment
	else:
		return DEFAULT_RESTORE_BUTTON_ALIGNMENT

## Resets all settings to their default values
##
## This method resets both text size multiplier and alignment to defaults and emits the settings_reset signal.
func reset_to_defaults() -> void:
	set_text_size_multiplier(DEFAULT_TEXT_SIZE_MULTIPLIER)
	set_restore_button_alignment(DEFAULT_RESTORE_BUTTON_ALIGNMENT)
	settings_reset.emit()

## Shows the settings panel centered on screen
##
## Convenience method that wraps popup_centered() for easier API usage.
func show_settings() -> void:
	popup_centered()

## Called when the text size slider value changes
##
## Updates the value display label to show the current multiplier.
## @param value: The new slider value
func _on_text_size_slider_changed(value: float) -> void:
	_update_text_size_label(value)

## Called when the Reset to Default button is pressed
##
## Resets settings to defaults and emits the settings_reset signal.
func _on_reset_button_pressed() -> void:
	reset_to_defaults()

## Called when the Apply button is pressed
##
## Emits the settings_applied signal with the current settings values.
func _on_apply_pressed() -> void:
	settings_applied.emit(get_text_size_multiplier(), get_restore_button_alignment())

## Updates the text size value label to show the current multiplier
##
## @param value: The text size multiplier to display
func _update_text_size_label(value: float) -> void:
	_text_size_value_label.text = "%.1fx" % value

## Validates that a text size multiplier value is within acceptable bounds
##
## @param value: The value to validate
## @return: True if the value is valid, false otherwise
func is_valid_text_size_multiplier(value: float) -> bool:
	return value >= MIN_TEXT_SIZE_MULTIPLIER and value <= MAX_TEXT_SIZE_MULTIPLIER
