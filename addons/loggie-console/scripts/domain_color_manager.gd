class_name DomainColorManager extends RefCounted

## Centralized domain color management for LoggieConsole
## Provides consistent color mapping across all console components

const LoggieConsoleColorSettings = preload("res://addons/loggie-console/resources/loggie_console_color_settings.gd")

## Domain color mapping information
class DomainColorInfo:
	var domain_name: String
	var color: Color
	var palette_index: int
	var cycle_count: int
	var is_variation: bool
	
	func _init(p_domain_name: String, p_color: Color, p_palette_index: int, p_cycle_count: int) -> void:
		domain_name = p_domain_name
		color = p_color
		palette_index = p_palette_index
		cycle_count = p_cycle_count
		is_variation = p_cycle_count > 0

## Color usage statistics and diagnostic information
class ColorUsageInfo:
	var total_domains: int
	var palette_size: int
	var current_cycle: int
	var next_color_index: int
	var remaining_in_current_cycle: int
	var has_color_variations: bool
	
	func _init(p_total_domains: int, p_palette_size: int, p_current_cycle: int, p_next_color_index: int, p_remaining_in_current_cycle: int, p_has_color_variations: bool) -> void:
		total_domains = p_total_domains
		palette_size = p_palette_size
		current_cycle = p_current_cycle
		next_color_index = p_next_color_index
		remaining_in_current_cycle = p_remaining_in_current_cycle
		has_color_variations = p_has_color_variations

# Domain color mapping storage
var _domain_colors: Dictionary[String, DomainColorInfo] = {}
var _color_index: int = 0

# Color settings reference - injected by console
var _color_settings: LoggieConsoleColorSettings


## Initialize the color manager with settings
func initialize(color_settings: LoggieConsoleColorSettings) -> void:
	_color_settings = color_settings

## Get or assign a color for a domain
func get_domain_color(domain: String) -> Color:
	if domain.is_empty():
		return Color.WHITE
	
	if not _color_settings:
		push_error("DomainColorManager not initialized with color settings")
		return Color.WHITE
	
	if not _domain_colors.has(domain):
		# Get effective palette from settings
		var palette: Array[Color] = _color_settings.get_effective_palette()
		if palette.is_empty():
			return Color.WHITE
		
		# Assign a new color from the palette with potential variations
		var palette_index: int = _color_index % palette.size()
		var cycle_count: int = _color_index / palette.size() 
		
		var base_color: Color = palette[palette_index]
		var color: Color = _get_color_variation(base_color, cycle_count)
		
		var new_color_info: DomainColorInfo = DomainColorInfo.new(domain, color, palette_index, cycle_count)
		_domain_colors[domain] = new_color_info
		_color_index += 1
	
	var existing_color_info: DomainColorInfo = _domain_colors[domain]
	return existing_color_info.color

## Get HTML color string for domain (for BBCode)
func get_domain_color_html(domain: String) -> String:
	return get_domain_color(domain).to_html(false)

## Check if domain has assigned color
func has_domain_color(domain: String) -> bool:
	return _domain_colors.has(domain)

## Get domain color information for a specific domain
func get_domain_color_info(domain: String) -> DomainColorInfo:
	if not _domain_colors.has(domain):
		# Trigger color assignment by calling get_domain_color
		get_domain_color(domain)
	
	return _domain_colors[domain]

## Get all registered domains with their color information
func get_all_domain_color_infos() -> Array[DomainColorInfo]:
	var infos: Array[DomainColorInfo] = []
	for domain_color_info: DomainColorInfo in _domain_colors.values():
		infos.append(domain_color_info)
	return infos

## Get diagnostic information about color usage and cycles
func get_color_usage_info() -> ColorUsageInfo:
	if not _color_settings:
		# Return default info if not initialized
		return ColorUsageInfo.new(0, 0, 0, 0, 0, false)
	
	var palette: Array[Color] = _color_settings.get_effective_palette()
	var palette_size: int = palette.size()
	
	if palette_size == 0:
		return ColorUsageInfo.new(0, 0, 0, 0, 0, false)
	
	var current_cycle: int = _color_index / palette_size
	var remaining_in_cycle: int = palette_size - (_color_index % palette_size)
	
	return ColorUsageInfo.new(
		_domain_colors.size(),
		palette_size,
		current_cycle,
		_color_index % palette_size,
		remaining_in_cycle,
		current_cycle > 0
	)

## Clear all color assignments (for testing/reset)
func clear_all_colors() -> void:
	_domain_colors.clear()
	_color_index = 0

## Get the current color palette for reference
func get_color_palette() -> Array[Color]:
	if not _color_settings:
		return []
	return _color_settings.get_effective_palette()

# Color variation cycle constants
const CYCLE_2_BRIGHTNESS_MULT: float = 1.0  # Second cycle - increase brightness
const CYCLE_3_SATURATION_MIN: float = 0.3   # Third cycle - minimum saturation
const CYCLE_4_BRIGHTNESS_MULT: float = 0.7  # Fourth cycle - brightness multiplier  
const CYCLE_4_BRIGHTNESS_MIN: float = 0.4   # Fourth cycle - minimum brightness
const CYCLE_5_SATURATION_MULT: float = 1.2  # Fifth cycle - saturation multiplier
const CYCLE_5_BRIGHTNESS_MULT: float = 0.85 # Fifth cycle - brightness multiplier
const CYCLE_5_BRIGHTNESS_MIN: float = 0.5   # Fifth cycle - minimum brightness

# Mathematical variation constants for cycles beyond 5
const MATH_VAR_BRIGHTNESS_STEP: float = 0.25  # Brightness variation step
const MATH_VAR_SATURATION_STEP: float = 0.2   # Saturation variation step
const MATH_VAR_MIN_BRIGHTNESS: float = 0.3    # Minimum brightness for math variations
const MATH_VAR_MIN_SATURATION: float = 0.2    # Minimum saturation for math variations

## Create color variations for domains beyond the initial palette
## Uses brightness and saturation adjustments to create distinguishable variations
func _get_color_variation(base_color: Color, cycle_count: int) -> Color:
	if not _color_settings:
		return base_color
	
	# Check if variations are enabled
	if not _color_settings.enable_color_variations or cycle_count == 0:
		# First cycle or variations disabled - use original colors
		return base_color
	
	# Get variation settings
	var brightness_factor: float = _color_settings.variation_brightness_factor
	var saturation_factor: float = _color_settings.variation_saturation_factor
	
	# Get HSV components directly from Color
	var hue: float = base_color.h
	var saturation: float = base_color.s
	var value: float = base_color.v
	
	match cycle_count:
		1:
			# Second cycle - Increase brightness
			value = minf(value * brightness_factor, CYCLE_2_BRIGHTNESS_MULT)
		2:
			# Third cycle - Decrease saturation (more pastel)
			saturation = maxf(saturation * saturation_factor, CYCLE_3_SATURATION_MIN)
		3:
			# Fourth cycle - Decrease brightness
			value = maxf(value * CYCLE_4_BRIGHTNESS_MULT, CYCLE_4_BRIGHTNESS_MIN)
		4:
			# Fifth cycle - High saturation, medium brightness
			saturation = minf(saturation * CYCLE_5_SATURATION_MULT, 1.0)
			value = maxf(minf(value * CYCLE_5_BRIGHTNESS_MULT, 1.0), CYCLE_5_BRIGHTNESS_MIN)
		_:
			# Beyond fifth cycle - Use mathematical variations
			var brightness_mod: float = 1.0 + (cycle_count % 3) * MATH_VAR_BRIGHTNESS_STEP - MATH_VAR_BRIGHTNESS_STEP  # -0.25, 0, +0.25
			var saturation_mod: float = 1.0 + ((cycle_count + 1) % 3) * MATH_VAR_SATURATION_STEP - MATH_VAR_SATURATION_STEP  # -0.2, 0, +0.2
			
			value = maxf(minf(value * brightness_mod, 1.0), MATH_VAR_MIN_BRIGHTNESS)
			saturation = maxf(minf(saturation * saturation_mod, 1.0), MATH_VAR_MIN_SATURATION)
	
	return Color.from_hsv(hue, saturation, value)
