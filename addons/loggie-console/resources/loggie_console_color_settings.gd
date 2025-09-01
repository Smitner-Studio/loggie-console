@tool
class_name LoggieConsoleColorSettings extends Resource

## Configurable color palette settings for LoggieConsole domain colors
##
## This resource stores the configurable color palette used for domain highlighting
## in the console. It can be modified through the editor plugin settings interface.

# Color theme palettes - popular themes for terminal/console applications

# GruvBox theme - Retro groove colors
static var GRUVBOX_PALETTE: Array[Color] = [
	Color("#fb4934"),  # Red
	Color("#b8bb26"),  # Green
	Color("#fabd2f"),  # Yellow
	Color("#83a598"),  # Blue
	Color("#d3869b"),  # Purple
	Color("#8ec07c"),  # Aqua
	Color("#fe8019"),  # Orange
	Color("#f38ba8"),  # Pink
	Color("#a89984"),  # Gray
	Color("#ebdbb2"),  # Light Gray
	Color("#cc241d"),  # Dark Red
	Color("#98971a"),  # Dark Green
	Color("#d79921"),  # Dark Yellow
	Color("#458588"),  # Dark Blue
	Color("#b16286"),  # Dark Purple
	Color("#689d6a"),  # Dark Aqua
	Color("#d65d0e"),  # Dark Orange
	Color("#fb2e01"),  # Bright Red
	Color("#79740e"),  # Olive
	Color("#427b58")   # Forest Green
]

# Dracula theme - Dark purple theme, very popular
static var DRACULA_PALETTE: Array[Color] = [
	Color("#ff5555"),  # Red
	Color("#50fa7b"),  # Green
	Color("#f1fa8c"),  # Yellow
	Color("#bd93f9"),  # Purple
	Color("#ff79c6"),  # Pink
	Color("#8be9fd"),  # Cyan
	Color("#ffb86c"),  # Orange
	Color("#f8f8f2"),  # Foreground
	Color("#6272a4"),  # Comment
	Color("#44475a"),  # Selection
	Color("#ff6e6e"),  # Light Red
	Color("#69ff94"),  # Light Green
	Color("#ffffa5"),  # Light Yellow
	Color("#d6acff"),  # Light Purple
	Color("#ff92df"),  # Light Pink
	Color("#a4ffff"),  # Light Cyan
	Color("#ffd700"),  # Gold
	Color("#ff1493"),  # Deep Pink
	Color("#00ff7f"),  # Spring Green
	Color("#1e90ff")   # Dodger Blue
]

# Monokai theme - Dark theme with vibrant colors
static var MONOKAI_PALETTE: Array[Color] = [
	Color("#f92672"),  # Red/Pink
	Color("#a6e22e"),  # Green
	Color("#e6db74"),  # Yellow
	Color("#66d9ef"),  # Blue/Cyan
	Color("#ae81ff"),  # Purple
	Color("#fd971f"),  # Orange
	Color("#f8f8f2"),  # White
	Color("#75715e"),  # Comment
	Color("#49483e"),  # Selection
	Color("#272822"),  # Background
	Color("#ff6188"),  # Light Pink
	Color("#78dce8"),  # Light Cyan
	Color("#ab9df2"),  # Light Purple
	Color("#ffd866"),  # Light Yellow
	Color("#ff9867"),  # Light Orange
	Color("#a9dc76"),  # Light Green
	Color("#fc9867"),  # Peach
	Color("#ff6d7e"),  # Salmon
	Color("#939293"),  # Gray
	Color("#e1efff")   # Light Blue
]

# Solarized Dark theme - Popular academic theme
static var SOLARIZED_DARK_PALETTE: Array[Color] = [
	Color("#dc322f"),  # Red
	Color("#859900"),  # Green
	Color("#b58900"),  # Yellow
	Color("#268bd2"),  # Blue
	Color("#d33682"),  # Magenta
	Color("#2aa198"),  # Cyan
	Color("#cb4b16"),  # Orange
	Color("#839496"),  # Base0
	Color("#657b83"),  # Base00
	Color("#586e75"),  # Base01
	Color("#073642"),  # Base02
	Color("#002b36"),  # Base03
	Color("#eee8d5"),  # Base2
	Color("#fdf6e3"),  # Base3
	Color("#93a1a1"),  # Base1
	Color("#6c71c4"),  # Violet
	Color("#ef2929"),  # Bright Red
	Color("#34e2e2"),  # Bright Cyan
	Color("#8ae234"),  # Bright Green
	Color("#fcaf3e")   # Bright Yellow
]

# One Dark theme - Atom editor's popular theme
static var ONE_DARK_PALETTE: Array[Color] = [
	Color("#e06c75"),  # Red
	Color("#98c379"),  # Green
	Color("#e5c07b"),  # Yellow
	Color("#61afef"),  # Blue
	Color("#c678dd"),  # Purple
	Color("#56b6c2"),  # Cyan
	Color("#d19a66"),  # Orange
	Color("#abb2bf"),  # Foreground
	Color("#5c6370"),  # Comment
	Color("#3e4451"),  # Selection
	Color("#be5046"),  # Dark Red
	Color("#282c34"),  # Background
	Color("#21252b"),  # Dark Background
	Color("#181a1f"),  # Darker Background
	Color("#f92672"),  # Bright Red
	Color("#a6e22e"),  # Bright Green
	Color("#66d9ef"),  # Bright Blue
	Color("#ae81ff"),  # Bright Purple
	Color("#fd971f"),  # Bright Orange
	Color("#e6db74")   # Bright Yellow
]

# Nord theme - Arctic-inspired theme
static var NORD_PALETTE: Array[Color] = [
	Color("#bf616a"),  # Red
	Color("#a3be8c"),  # Green
	Color("#ebcb8b"),  # Yellow
	Color("#81a1c1"),  # Blue
	Color("#b48ead"),  # Purple
	Color("#88c0d0"),  # Cyan
	Color("#d08770"),  # Orange
	Color("#e5e9f0"),  # Snow Storm 1
	Color("#d8dee9"),  # Snow Storm 2
	Color("#eceff4"),  # Snow Storm 3
	Color("#4c566a"),  # Polar Night 1
	Color("#434c5e"),  # Polar Night 2
	Color("#3b4252"),  # Polar Night 3
	Color("#2e3440"),  # Polar Night 4
	Color("#5e81ac"),  # Frost 1
	Color("#94a3b8"),  # Light Gray
	Color("#6b7280"),  # Medium Gray
	Color("#9ca3af"),  # Cool Gray
	Color("#f87171"),  # Light Red
	Color("#34d399")   # Light Green
]

## Current color palette for domain assignment
@export var color_palette: Array[Color] = []

## Color theme name for reference
@export var theme_name: String = "GruvBox Dark"

# Color variation constants
const DEFAULT_BRIGHTNESS_FACTOR: float = 1.3
const MIN_BRIGHTNESS_FACTOR: float = 0.5
const MAX_BRIGHTNESS_FACTOR: float = 2.0

const DEFAULT_SATURATION_FACTOR: float = 0.6
const MIN_SATURATION_FACTOR: float = 0.3
const MAX_SATURATION_FACTOR: float = 1.2

## Whether to use color variations when palette is exhausted
@export var enable_color_variations: bool = true

## Brightness adjustment factor for color variations (0.5 to 2.0)
@export var variation_brightness_factor: float = DEFAULT_BRIGHTNESS_FACTOR

## Saturation adjustment factor for color variations (0.3 to 1.2)
@export var variation_saturation_factor: float = DEFAULT_SATURATION_FACTOR

## Initialize with default GruvBox palette
func _init() -> void:
	if color_palette.is_empty():
		reset_to_gruvbox_theme()

## Reset to GruvBox default theme
func reset_to_gruvbox_theme() -> void:
	apply_theme("GruvBox Dark")

## Apply a specific color theme by name
func apply_theme(theme: String) -> void:
	theme_name = theme
	
	match theme:
		"GruvBox Dark":
			color_palette = GRUVBOX_PALETTE.duplicate()
		"Dracula":
			color_palette = DRACULA_PALETTE.duplicate()
		"Monokai":
			color_palette = MONOKAI_PALETTE.duplicate()
		"Solarized Dark":
			color_palette = SOLARIZED_DARK_PALETTE.duplicate()
		"One Dark":
			color_palette = ONE_DARK_PALETTE.duplicate()
		"Nord":
			color_palette = NORD_PALETTE.duplicate()
		_:
			# Default to GruvBox if theme not recognized
			color_palette = GRUVBOX_PALETTE.duplicate()
			theme_name = "GruvBox Dark"
	
	# Apply default settings for all themes
	enable_color_variations = true
	variation_brightness_factor = DEFAULT_BRIGHTNESS_FACTOR
	variation_saturation_factor = DEFAULT_SATURATION_FACTOR

## Get list of available theme names
func get_available_themes() -> Array[String]:
	return [
		"GruvBox Dark",
		"Dracula", 
		"Monokai",
		"Solarized Dark",
		"One Dark",
		"Nord"
	]

## Get the effective color palette 
func get_effective_palette() -> Array[Color]:
	return color_palette.duplicate()

## Validate all settings after loading
func validate() -> void:
	# Ensure we have at least some colors
	if color_palette.is_empty():
		reset_to_gruvbox_theme()
	
	# Validate variation factors are in reasonable ranges
	variation_brightness_factor = clampf(variation_brightness_factor, MIN_BRIGHTNESS_FACTOR, MAX_BRIGHTNESS_FACTOR)
	variation_saturation_factor = clampf(variation_saturation_factor, MIN_SATURATION_FACTOR, MAX_SATURATION_FACTOR)

## Get variation settings for the domain color manager
func get_variation_settings() -> Dictionary[String, Variant]:
	var settings: Dictionary[String, Variant] = {}
	settings["enable_variations"] = enable_color_variations
	settings["brightness_factor"] = variation_brightness_factor
	settings["saturation_factor"] = variation_saturation_factor
	return settings
