@tool
class_name DomainColorManager extends RefCounted

## Centralized domain color management for LoggieConsole
## Provides consistent color mapping across all console components

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
var _domain_colors: Dictionary = {}  # String -> DomainColorInfo
var _color_index: int = 0

# Predefined color palette for domains
const DOMAIN_COLOR_PALETTE: Array[Color] = [
	Color("#FF6B6B"),  # Red
	Color("#4ECDC4"),  # Teal
	Color("#45B7D1"),  # Blue
	Color("#96CEB4"),  # Green
	Color("#FECA57"),  # Yellow
	Color("#FF9FF3"),  # Pink
	Color("#54A0FF"),  # Light Blue
	Color("#5F27CD"),  # Purple
	Color("#00D2D3"),  # Cyan
	Color("#FF9F43"),  # Orange
	Color("#10AC84"),  # Mint
	Color("#EE5A24"),  # Dark Orange
	Color("#0984E3"),  # Royal Blue
	Color("#6C5CE7"),  # Violet
	Color("#A29BFE"),  # Light Purple
	Color("#FD79A8"),  # Rose
	Color("#FDCB6E"),  # Light Yellow
	Color("#6C5CE7"),  # Indigo
	Color("#00B894"),  # Emerald
	Color("#E84393")   # Magenta
]


## Get or assign a color for a domain
func get_domain_color(domain: String) -> Color:
	if domain.is_empty():
		return Color.WHITE
	
	if not _domain_colors.has(domain):
		# Assign a new color from the palette with potential variations
		var palette_index: int = _color_index % DOMAIN_COLOR_PALETTE.size()
		var cycle_count: int = _color_index / DOMAIN_COLOR_PALETTE.size() 
		
		var base_color: Color = DOMAIN_COLOR_PALETTE[palette_index]
		var color: Color = _get_color_variation(base_color, cycle_count)
		
		var new_color_info: DomainColorInfo = DomainColorInfo.new(domain, color, palette_index, cycle_count)
		_domain_colors[domain] = new_color_info
		_color_index += 1
	
	var existing_color_info: DomainColorInfo = _domain_colors[domain] as DomainColorInfo
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
	
	return _domain_colors[domain] as DomainColorInfo

## Get all registered domains with their color information
func get_all_domain_color_infos() -> Array[DomainColorInfo]:
	var infos: Array[DomainColorInfo] = []
	for domain_color_info: DomainColorInfo in _domain_colors.values():
		infos.append(domain_color_info)
	return infos

## Get diagnostic information about color usage and cycles
func get_color_usage_info() -> ColorUsageInfo:
	var current_cycle: int = _color_index / DOMAIN_COLOR_PALETTE.size()
	var remaining_in_cycle: int = DOMAIN_COLOR_PALETTE.size() - (_color_index % DOMAIN_COLOR_PALETTE.size())
	
	return ColorUsageInfo.new(
		_domain_colors.size(),
		DOMAIN_COLOR_PALETTE.size(),
		current_cycle,
		_color_index % DOMAIN_COLOR_PALETTE.size(),
		remaining_in_cycle,
		current_cycle > 0
	)

## Clear all color assignments (for testing/reset)
func clear_all_colors() -> void:
	_domain_colors.clear()
	_color_index = 0

## Get the color palette for reference
func get_color_palette() -> Array[Color]:
	return DOMAIN_COLOR_PALETTE

## Create color variations for domains beyond the initial palette
## Uses brightness and saturation adjustments to create distinguishable variations
func _get_color_variation(base_color: Color, cycle_count: int) -> Color:
	if cycle_count == 0:
		# First cycle - use original colors
		return base_color
	
	# Get HSV components directly from Color
	var hue: float = base_color.h
	var saturation: float = base_color.s
	var value: float = base_color.v
	
	match cycle_count:
		1:
			# Second cycle - Increase brightness
			value = minf(value * 1.3, 1.0)
		2:
			# Third cycle - Decrease saturation (more pastel)
			saturation = maxf(saturation * 0.6, 0.3)
		3:
			# Fourth cycle - Decrease brightness
			value = maxf(value * 0.7, 0.4)
		4:
			# Fifth cycle - High saturation, medium brightness
			saturation = minf(saturation * 1.2, 1.0)
			value = maxf(minf(value * 0.85, 1.0), 0.5)
		_:
			# Beyond fifth cycle - Use mathematical variations
			var brightness_mod: float = 1.0 + (cycle_count % 3) * 0.25 - 0.25  # -0.25, 0, +0.25
			var saturation_mod: float = 1.0 + ((cycle_count + 1) % 3) * 0.2 - 0.2  # -0.2, 0, +0.2
			
			value = maxf(minf(value * brightness_mod, 1.0), 0.3)
			saturation = maxf(minf(saturation * saturation_mod, 1.0), 0.2)
	
	return Color.from_hsv(hue, saturation, value)
