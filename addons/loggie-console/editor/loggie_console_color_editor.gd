@tool
extends Control

## Editor interface for configuring LoggieConsole color settings
##
## Provides a user-friendly interface within the Godot editor for customizing
## domain color palettes, themes, and color variation settings.

const LoggieConsoleColorSettings = preload("res://addons/loggie-console/resources/loggie_console_color_settings.gd")

# UI Size constants
const TITLE_FONT_SIZE: int = 18
const HEADER_FONT_SIZE: int = 14
const STEP_SIZE: float = 0.1
const COLOR_RECT_SIZE: Vector2 = Vector2(30, 30)
const COLOR_PICKER_SIZE: Vector2 = Vector2(200, 150)

signal settings_changed(settings: LoggieConsoleColorSettings)

var _settings: LoggieConsoleColorSettings
var _color_containers: Array[ColorRect] = []
var _custom_color_containers: Array[HBoxContainer] = []

var _theme_label: Label
var _reset_button: Button
var _variations_checkbox: CheckBox
var _brightness_spinbox: SpinBox
var _saturation_spinbox: SpinBox
var _custom_colors_checkbox: CheckBox
var _palette_container: VBoxContainer
var _custom_colors_container: VBoxContainer

func _ready() -> void:
	_create_interface()
	
	# Refresh interface if settings were set before _ready
	if _settings:
		_refresh_interface()

## Initialize the editor with color settings
func initialize(settings: LoggieConsoleColorSettings) -> void:
	_settings = settings
	if _settings and _is_interface_ready():
		_refresh_interface()

## Create the editor interface
func _create_interface() -> void:
	# Main container
	var main_vbox: VBoxContainer = VBoxContainer.new()
	add_child(main_vbox)
	
	# Title
	var title: Label = Label.new()
	title.text = "LoggieConsole Color Settings"
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	main_vbox.add_child(title)
	
	# Theme section
	var theme_section: Control = _create_theme_section()
	main_vbox.add_child(theme_section)
	
	# Variations section
	var variations_section: Control = _create_variations_section()
	main_vbox.add_child(variations_section)
	
	# Custom colors section
	var custom_section: Control = _create_custom_colors_section()
	main_vbox.add_child(custom_section)
	
	# Palette preview section
	var palette_section: Control = _create_palette_section()
	main_vbox.add_child(palette_section)

## Create theme selection section
func _create_theme_section() -> Control:
	var section: VBoxContainer = VBoxContainer.new()
	
	var header: Label = Label.new()
	header.text = "Color Theme"
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	section.add_child(header)
	
	var hbox: HBoxContainer = HBoxContainer.new()
	section.add_child(hbox)
	
	_theme_label = Label.new()
	_theme_label.text = "Current: GruvBox Dark"
	hbox.add_child(_theme_label)
	
	_reset_button = Button.new()
	_reset_button.text = "Reset to GruvBox"
	_reset_button.pressed.connect(_on_reset_pressed)
	hbox.add_child(_reset_button)
	
	return section

## Create color variations section
func _create_variations_section() -> Control:
	var section: VBoxContainer = VBoxContainer.new()
	
	var header: Label = Label.new()
	header.text = "Color Variations"
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	section.add_child(header)
	
	_variations_checkbox = CheckBox.new()
	_variations_checkbox.text = "Enable color variations when palette is exhausted"
	_variations_checkbox.toggled.connect(_on_variations_toggled)
	section.add_child(_variations_checkbox)
	
	var brightness_hbox: HBoxContainer = HBoxContainer.new()
	section.add_child(brightness_hbox)
	
	var brightness_label: Label = Label.new()
	brightness_label.text = "Brightness Factor:"
	brightness_hbox.add_child(brightness_label)
	
	_brightness_spinbox = SpinBox.new()
	_brightness_spinbox.min_value = LoggieConsoleColorSettings.MIN_BRIGHTNESS_FACTOR
	_brightness_spinbox.max_value = LoggieConsoleColorSettings.MAX_BRIGHTNESS_FACTOR
	_brightness_spinbox.step = STEP_SIZE
	_brightness_spinbox.value = LoggieConsoleColorSettings.DEFAULT_BRIGHTNESS_FACTOR
	_brightness_spinbox.value_changed.connect(_on_brightness_changed)
	brightness_hbox.add_child(_brightness_spinbox)
	
	var saturation_hbox: HBoxContainer = HBoxContainer.new()
	section.add_child(saturation_hbox)
	
	var saturation_label: Label = Label.new()
	saturation_label.text = "Saturation Factor:"
	saturation_hbox.add_child(saturation_label)
	
	_saturation_spinbox = SpinBox.new()
	_saturation_spinbox.min_value = LoggieConsoleColorSettings.MIN_SATURATION_FACTOR
	_saturation_spinbox.max_value = LoggieConsoleColorSettings.MAX_SATURATION_FACTOR
	_saturation_spinbox.step = STEP_SIZE
	_saturation_spinbox.value = LoggieConsoleColorSettings.DEFAULT_SATURATION_FACTOR
	_saturation_spinbox.value_changed.connect(_on_saturation_changed)
	saturation_hbox.add_child(_saturation_spinbox)
	
	return section

## Create custom colors section
func _create_custom_colors_section() -> Control:
	var section: VBoxContainer = VBoxContainer.new()
	
	var header: Label = Label.new()
	header.text = "Custom Colors"
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	section.add_child(header)
	
	_custom_colors_checkbox = CheckBox.new()
	_custom_colors_checkbox.text = "Use custom colors in addition to theme palette"
	_custom_colors_checkbox.toggled.connect(_on_custom_colors_toggled)
	section.add_child(_custom_colors_checkbox)
	
	_custom_colors_container = VBoxContainer.new()
	section.add_child(_custom_colors_container)
	
	var add_button: Button = Button.new()
	add_button.text = "Add Custom Color"
	add_button.pressed.connect(_on_add_custom_color)
	section.add_child(add_button)
	
	return section

## Create palette preview section
func _create_palette_section() -> Control:
	var section: VBoxContainer = VBoxContainer.new()
	
	var header: Label = Label.new()
	header.text = "Color Palette Preview"
	header.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	section.add_child(header)
	
	_palette_container = VBoxContainer.new()
	section.add_child(_palette_container)
	
	return section

## Check if interface elements are ready
func _is_interface_ready() -> bool:
	return (_theme_label != null and _variations_checkbox != null and 
			_brightness_spinbox != null and _saturation_spinbox != null and
			_custom_colors_checkbox != null and _palette_container != null and
			_custom_colors_container != null)

## Refresh the interface with current settings
func _refresh_interface() -> void:
	if not _settings or not _is_interface_ready():
		return
	
	_theme_label.text = "Current: " + _settings.theme_name
	_variations_checkbox.button_pressed = _settings.enable_color_variations
	_brightness_spinbox.value = _settings.variation_brightness_factor
	_saturation_spinbox.value = _settings.variation_saturation_factor
	_custom_colors_checkbox.button_pressed = _settings.use_custom_colors
	
	_refresh_palette_preview()
	_refresh_custom_colors()

## Refresh the palette preview
func _refresh_palette_preview() -> void:
	# Clear existing preview
	for child in _palette_container.get_children():
		child.queue_free()
	_color_containers.clear()
	
	if not _settings:
		return
	
	var colors: Array[Color] = _settings.get_effective_palette()
	var grid: GridContainer = GridContainer.new()
	grid.columns = 8
	_palette_container.add_child(grid)
	
	for i: int in range(colors.size()):
		var color: Color = colors[i]
		var color_rect: ColorRect = ColorRect.new()
		color_rect.color = color
		color_rect.custom_minimum_size = COLOR_RECT_SIZE
		color_rect.tooltip_text = "Color %d: %s" % [i + 1, color.to_html()]
		grid.add_child(color_rect)
		_color_containers.append(color_rect)

## Refresh custom colors section
func _refresh_custom_colors() -> void:
	# Clear existing custom color controls
	for child in _custom_colors_container.get_children():
		child.queue_free()
	_custom_color_containers.clear()
	
	if not _settings:
		return
	
	for i: int in range(_settings.custom_colors.size()):
		_add_custom_color_control(i)

## Add a custom color control at the specified index
func _add_custom_color_control(index: int) -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	_custom_colors_container.add_child(hbox)
	
	var color_picker: ColorPicker = ColorPicker.new()
	color_picker.custom_minimum_size = COLOR_PICKER_SIZE
	if index < _settings.custom_colors.size():
		color_picker.color = _settings.custom_colors[index]
	color_picker.color_changed.connect(_on_custom_color_changed.bind(index))
	hbox.add_child(color_picker)
	
	var remove_button: Button = Button.new()
	remove_button.text = "Remove"
	remove_button.pressed.connect(_on_remove_custom_color.bind(index))
	hbox.add_child(remove_button)
	
	_custom_color_containers.append(hbox)

## Signal handlers
func _on_reset_pressed() -> void:
	if _settings:
		_settings.reset_to_gruvbox_theme()
		_refresh_interface()
		_emit_settings_changed()

func _on_variations_toggled(enabled: bool) -> void:
	if _settings:
		_settings.enable_color_variations = enabled
		_emit_settings_changed()

func _on_brightness_changed(value: float) -> void:
	if _settings:
		_settings.variation_brightness_factor = value
		_emit_settings_changed()

func _on_saturation_changed(value: float) -> void:
	if _settings:
		_settings.variation_saturation_factor = value
		_emit_settings_changed()

func _on_custom_colors_toggled(enabled: bool) -> void:
	if _settings:
		_settings.use_custom_colors = enabled
		_refresh_palette_preview()
		_emit_settings_changed()

func _on_add_custom_color() -> void:
	if _settings and _settings.add_custom_color(Color.WHITE):
		_refresh_custom_colors()
		_refresh_palette_preview()
		_emit_settings_changed()

func _on_remove_custom_color(index: int) -> void:
	if _settings and _settings.remove_custom_color(index):
		_refresh_custom_colors()
		_refresh_palette_preview()
		_emit_settings_changed()

func _on_custom_color_changed(index: int, color: Color) -> void:
	if _settings and index < _settings.custom_colors.size():
		_settings.custom_colors[index] = color
		_refresh_palette_preview()
		_emit_settings_changed()

func _emit_settings_changed() -> void:
	settings_changed.emit(_settings)