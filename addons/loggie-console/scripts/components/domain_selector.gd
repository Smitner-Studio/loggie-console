@tool
class_name DomainSelector extends MenuButton

## Standalone domain selector component for filtering log messages by domain
## Provides clean interface with proper signal-based communication

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")
const DomainColorManager = preload("res://addons/loggie-console/scripts/domain_color_manager.gd")

# Signals
signal domains_changed(enabled_domains: Array[String])

# Properties
var _enabled_domains: Array[String] = []
var _all_domains: Array[String] = []
var _domain_popup: PopupMenu
var _color_manager: DomainColorManager

# Constants
const ALL_ITEM_ID = 0
const SEPARATOR_ID = 1
const DOMAIN_ID_OFFSET = 2


func _ready() -> void:
	_domain_popup = get_popup()
	_domain_popup.id_pressed.connect(_on_domain_selected)
	_initialize_empty_state()

## Set the domain color manager instance
func set_color_manager(color_manager: DomainColorManager) -> void:
	_color_manager = color_manager

## Initialize the selector with available domains
func set_domains(domains: Array[String]) -> void:
	_all_domains = domains.duplicate()
	_enabled_domains = domains.duplicate()
	_rebuild_popup()
	_update_button_text()
	domains_changed.emit(_enabled_domains)

## Initialize the selector with all domains, but only enable selected ones
## Console domains appear normally but are unselected by default
func set_domains_with_console_unselected(all_domains: Array[String], enabled_domains: Array[String], console_domains: Array[String]) -> void:
	_all_domains = all_domains.duplicate()
	_enabled_domains = enabled_domains.duplicate()
	_rebuild_popup_with_console_unselected(console_domains)
	_update_button_text()
	domains_changed.emit(_enabled_domains)

## Add a new domain to the selector (for dynamic discovery)
func add_domain(domain_name: String) -> void:
	if domain_name.is_empty() or _all_domains.has(domain_name):
		return
	
	_all_domains.append(domain_name)
	_enabled_domains.append(domain_name)
	
	# Add new item to popup with color icon
	var display_name = _get_domain_display_name(domain_name)
	var color_icon = _create_domain_color_icon(domain_name)
	var item_id = _get_domain_item_id(_all_domains.size() - 1)
	
	_domain_popup.add_check_item(display_name, item_id)
	_domain_popup.set_item_icon(item_id, color_icon)
	_domain_popup.set_item_checked(item_id, true)
	
	_update_all_checkbox()
	_update_button_text()
	domains_changed.emit(_enabled_domains)

## Get currently enabled domains
func get_enabled_domains() -> Array[String]:
	return _enabled_domains.duplicate()

## Check if a domain is enabled
func is_domain_enabled(domain_name: String) -> bool:
	return _enabled_domains.has(domain_name)

## Private methods

## Create colored icon for domain display in popup
func _create_domain_color_icon(domain_name: String, size: int = 12) -> ImageTexture:
	var color: Color = Color.WHITE  # Default color
	if _color_manager:
		color = _color_manager.get_domain_color(domain_name)
	
	# Create a small colored square image
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	
	# Convert to texture
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	return texture

## Get display name for domain (without color formatting)
func _get_domain_display_name(domain_name: String) -> String:
	return domain_name if not domain_name.is_empty() else "(default)"

func _initialize_empty_state() -> void:
	_domain_popup.clear()
	_domain_popup.add_item("No domains available")
	_domain_popup.set_item_disabled(0, true)
	text = "Domains: None"

func _rebuild_popup() -> void:
	_domain_popup.clear()
	
	# Add "All" toggle
	_domain_popup.add_check_item("All", ALL_ITEM_ID)
	_domain_popup.set_item_checked(ALL_ITEM_ID, _enabled_domains.size() == _all_domains.size())
	
	# Add separator
	_domain_popup.add_separator()
	
	# Add individual domain items with color icons
	for i in range(_all_domains.size()):
		var domain_name = _all_domains[i]
		var display_name = _get_domain_display_name(domain_name)
		var color_icon = _create_domain_color_icon(domain_name)
		var item_id = _get_domain_item_id(i)
		
		_domain_popup.add_check_item(display_name, item_id)
		_domain_popup.set_item_icon(item_id, color_icon)
		_domain_popup.set_item_checked(item_id, _enabled_domains.has(domain_name))

## Builds popup with console domain unselected by default (no separator)
func _rebuild_popup_with_console_unselected(console_domains: Array[String]) -> void:
	_domain_popup.clear()
	
	# Add "All" toggle (only for non-console domains)
	_domain_popup.add_check_item("All", ALL_ITEM_ID)
	var non_console_domains = []
	for domain in _all_domains:
		if not console_domains.has(domain):
			non_console_domains.append(domain)
	_domain_popup.set_item_checked(ALL_ITEM_ID, _enabled_domains.size() == non_console_domains.size())
	
	# Add separator
	_domain_popup.add_separator()
	
	# Add all domain items in order with color icons
	for i in range(_all_domains.size()):
		var domain_name = _all_domains[i]
		var display_name: String
		
		# Use friendly name for console domain
		if console_domains.has(domain_name):
			display_name = "LoggieConsole"  # Simplified name for console domain
		else:
			display_name = domain_name if not domain_name.is_empty() else "(default)"
		
		# Create color icon for the domain
		var color_icon = _create_domain_color_icon(domain_name)
		
		var item_id = _get_domain_item_id(i)
		_domain_popup.add_check_item(display_name, item_id)
		_domain_popup.set_item_icon(item_id, color_icon)
		_domain_popup.set_item_checked(item_id, _enabled_domains.has(domain_name))

func _on_domain_selected(id: int) -> void:
	if id == ALL_ITEM_ID:
		_toggle_all_domains()
	else:
		_toggle_individual_domain(id)
	
	_update_all_checkbox()
	_update_button_text()
	domains_changed.emit(_enabled_domains)

func _toggle_all_domains() -> void:
	var current_all_state = _domain_popup.is_item_checked(ALL_ITEM_ID)
	var new_all_state = not current_all_state
	
	# Update all checkbox
	_domain_popup.set_item_checked(ALL_ITEM_ID, new_all_state)
	
	# Update all domain checkboxes and enabled list
	_enabled_domains.clear()
	for i in range(_all_domains.size()):
		var item_id = _get_domain_item_id(i)
		_domain_popup.set_item_checked(item_id, new_all_state)
		if new_all_state:
			_enabled_domains.append(_all_domains[i])

func _toggle_individual_domain(id: int) -> void:
	var domain_index = _get_domain_index_from_id(id)
	if domain_index < 0 or domain_index >= _all_domains.size():
		Loggie.msg("Invalid domain index %d for ID %d" % [domain_index, id]).domain(LoggieConsoleConstants.DOMAIN).warn()
		return
	
	var domain_name = _all_domains[domain_index]
	var current_state = _domain_popup.is_item_checked(id)
	var new_state = not current_state
	
	# Update checkbox
	_domain_popup.set_item_checked(id, new_state)
	
	# Update enabled domains list
	if new_state and not _enabled_domains.has(domain_name):
		_enabled_domains.append(domain_name)
	elif not new_state and _enabled_domains.has(domain_name):
		_enabled_domains.erase(domain_name)

func _update_all_checkbox() -> void:
	var all_enabled = _enabled_domains.size() == _all_domains.size()
	_domain_popup.set_item_checked(ALL_ITEM_ID, all_enabled)

func _update_button_text() -> void:
	var enabled_count = _enabled_domains.size()
	var total_count = _all_domains.size()
	
	if total_count == 0:
		text = "Domains: None"
	elif enabled_count == total_count:
		text = "Domains: All"
	elif enabled_count == 0:
		text = "Domains: None"
	elif enabled_count == 1:
		var domain_name = _enabled_domains[0]
		var display_name = _get_domain_display_name(domain_name)
		text = "Domains: " + display_name
	else:
		text = "Domains: %d selected" % enabled_count

func _get_domain_item_id(domain_index: int) -> int:
	return DOMAIN_ID_OFFSET + domain_index

func _get_domain_index_from_id(item_id: int) -> int:
	return item_id - DOMAIN_ID_OFFSET

## Saves current domain selection state to persistent settings
## Param settings: The settings resource to populate with current domain state
func save_settings_to_resource(settings: LoggieConsoleSettings) -> void:
	settings.enabled_domains = _enabled_domains.duplicate()
	settings.all_known_domains = _all_domains.duplicate()

## Loads domain selection state from persistent settings and rebuilds UI
## Automatically validates that enabled domains still exist in the known domains list
## Param settings: The settings resource containing saved domain state
func load_settings_from_resource(settings: LoggieConsoleSettings) -> void:
	_all_domains = settings.all_known_domains.duplicate()
	_enabled_domains = settings.enabled_domains.duplicate()
	
	# Remove any enabled domains that no longer exist in all_domains
	var valid_enabled_domains: Array[String] = []
	for domain in _enabled_domains:
		if _all_domains.has(domain):
			valid_enabled_domains.append(domain)
	_enabled_domains = valid_enabled_domains
	
	# Rebuild UI to reflect loaded state
	if _all_domains.size() > 0:
		_rebuild_popup()
		_update_button_text()
	else:
		_initialize_empty_state()
