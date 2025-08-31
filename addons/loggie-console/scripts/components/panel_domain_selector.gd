class_name PanelDomainSelector extends Control

## Panel-based domain selector component for filtering log messages by domain
## Provides enhanced UI with vertical list, hover "Only" buttons, and Apply/Cancel workflow
## Drop-in replacement for MenuButton-based DomainSelector with identical API

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")
const LoggieConsoleConstants = preload("res://addons/loggie-console/scripts/loggie_console_constants.gd")
const DomainItemScene = preload("res://addons/loggie-console/scenes/domain_item.tscn")
const DomainColorManager = preload("res://addons/loggie-console/scripts/domain_color_manager.gd")

# Signals - maintains API compatibility with existing DomainSelector
signal domains_changed(enabled_domains: Array[String])

# UI Components - exported for scene tree assignment
@export var trigger_button: Button
@export var domain_panel: PopupPanel
@export var select_all_button: Button
@export var select_none_button: Button
@export var scroll_container: ScrollContainer
@export var domain_list: VBoxContainer

# Domain management
var _all_domains: Array[String] = []
var _enabled_domains: Array[String] = []

# Domain item tracking
var _domain_items: Array[DomainItem] = []

# Panel state tracking
var _panel_is_open: bool = false

# Color management
var _color_manager: DomainColorManager 

# Panel sizing constants
const PANEL_WIDTH: int = 300
const PANEL_MAX_HEIGHT: int = 400
const PANEL_MIN_HEIGHT: int = 150

# Panel positioning constants
const PANEL_VERTICAL_GAP: int = 2
const PANEL_HORIZONTAL_MARGIN: int = 10

# Domain item layout constants  
const DOMAIN_ITEM_HEIGHT: int = 32
const PANEL_HEADER_HEIGHT: int = 40
const PANEL_SELECTION_CONTROLS_HEIGHT: int = 28
const PANEL_FOOTER_HEIGHT: int = 40
const PANEL_PADDING: int = 20


## Initializes the panel domain selector component
##
## Sets up UI connections, panel sizing, and attempts to load domains from Loggie.
## If no domains are found, initializes an empty state. All UI components must be 
## properly assigned via @export variables in the scene for initialization to succeed.
func _ready() -> void:
	if not trigger_button:
		_initialize_empty_state()
		return
		
	domain_panel.hide()
		
	# Connect UI signals
	trigger_button.pressed.connect(_on_trigger_button_pressed)
	select_all_button.pressed.connect(_on_select_all_button_pressed)
	select_none_button.pressed.connect(_on_select_none_button_pressed)
	
	# Connect popup signals to track state
	domain_panel.popup_hide.connect(_on_panel_hidden)
	domain_panel.about_to_popup.connect(_on_panel_about_to_show)
	
	# Set initial panel size
	domain_panel.size = Vector2(PANEL_WIDTH, PANEL_MIN_HEIGHT)
	
	# Try to initialize with real Loggie domains first
	_initialize_domains_from_loggie()
	
	# If no domains found, show empty state
	if _all_domains.is_empty():
		_initialize_empty_state()

## Set the domain color manager instance
func set_color_manager(color_manager: DomainColorManager) -> void:
	_color_manager = color_manager

## Initialize the selector with available domains
func set_domains(domains: Array[String]) -> void:
	_all_domains = domains.duplicate()
	_enabled_domains = domains.duplicate()
	_rebuild_domain_list()
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

## Initialize the selector with all domains, but only enable selected ones
## Console domains appear normally but are unselected by default
func set_domains_with_console_unselected(all_domains: Array[String], enabled_domains: Array[String], _console_domains: Array[String]) -> void:
	_all_domains = all_domains.duplicate()
	_enabled_domains = enabled_domains.duplicate()
	_rebuild_domain_list()
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

## Add a new domain to the selector (for dynamic discovery)
func add_domain(domain_name: String) -> void:
	if domain_name.is_empty() or _all_domains.has(domain_name):
		return
	
	_all_domains.append(domain_name)
	_enabled_domains.append(domain_name)
	
	_add_domain_item(domain_name, true)
	_update_trigger_button_text()
	_update_panel_size()
	domains_changed.emit(_enabled_domains)

## Get currently enabled domains
func get_enabled_domains() -> Array[String]:
	return _enabled_domains.duplicate()

## Check if a domain is enabled
func is_domain_enabled(domain_name: String) -> bool:
	return _enabled_domains.has(domain_name)

## Saves current domain selection state to persistent settings
func save_settings_to_resource(settings: LoggieConsoleSettings) -> void:
	settings.enabled_domains = _enabled_domains.duplicate()
	settings.all_known_domains = _all_domains.duplicate()

## Loads domain selection state from persistent settings and rebuilds UI
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
		_rebuild_domain_list()
		_update_trigger_button_text()
	else:
		_initialize_empty_state()

## Private methods

func _initialize_empty_state() -> void:
	if trigger_button:
		trigger_button.text = "Domains: None"
		trigger_button.tooltip_text = "No domains available"

func _initialize_domains_from_loggie() -> void:
	# Query Loggie for registered domains
	if not Loggie:
		return
		
	var loggie_domains: Array[String] = []
	
	# Get domains from Loggie's registered domains
	for domain_name: String in Loggie.domains.keys():
		if not domain_name.is_empty():
			loggie_domains.append(domain_name)
	
	# If we found domains, initialize with them
	if loggie_domains.size() > 0:
		set_domains(loggie_domains)
		Loggie.msg("Initialized domain selector with %d domains from Loggie" % loggie_domains.size()).domain(LoggieConsoleConstants.DOMAIN).info()
	else:
		_initialize_empty_state()

## Refresh domains from Loggie (useful for dynamic discovery)
func refresh_domains_from_loggie() -> void:
	if not Loggie:
		return
		
	var _current_domains: Array[String] = _all_domains.duplicate()
	var loggie_domains: Array[String] = []
	
	# Get current domains from Loggie
	for domain_name: String in Loggie.domains.keys():
		if not domain_name.is_empty():
			loggie_domains.append(domain_name)
	
	# Add any new domains we discovered
	var new_domains_added: bool = false
	for domain_name in loggie_domains:
		if not _all_domains.has(domain_name):
			add_domain(domain_name)
			new_domains_added = true
	
	if new_domains_added:
		Loggie.msg("Discovered new domains from Loggie").domain(LoggieConsoleConstants.DOMAIN).info()

func _on_trigger_button_pressed() -> void:
	if _all_domains.is_empty():
		return
		
	# Only open panel if not already open (button disabled when open)
	if not _panel_is_open:
		# Position and show panel
		domain_panel.popup()
		_position_panel()


func _on_select_all_button_pressed() -> void:
	# Select all domains instantly
	_enabled_domains = _all_domains.duplicate()
	_update_domain_items_state()
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

func _on_select_none_button_pressed() -> void:
	# Deselect all domains instantly
	_enabled_domains.clear()
	_update_domain_items_state()
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

## Intelligently positions the domain selection panel relative to the trigger button
##
## Calculates optimal panel placement considering viewport boundaries and trigger button
## position. Prefers positioning below and left-aligned to the trigger button, but will
## adjust to above or right-aligned if necessary to keep the panel fully visible.
## Ensures minimum margins from viewport edges for accessibility.
func _position_panel() -> void:
	if not trigger_button:
		return
		
	# Get trigger button global position and size
	var button_global_pos: Vector2 = trigger_button.global_position
	
	var button_size: Vector2 = trigger_button.size
	await get_tree().process_frame
	var panel_size: Vector2 = domain_panel.size
	
	# Get viewport rect for boundary checking
	var viewport: Viewport = get_viewport()
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	
	# Position directly below button, aligned to left edge
	var panel_pos: Vector2i = Vector2i(
		button_global_pos.x,
		button_global_pos.y + button_size.y + PANEL_VERTICAL_GAP
	)
	
	# Check if panel would go off-screen horizontally
	if panel_pos.x + panel_size.x > viewport_rect.size.x:
		# Align to right edge of button instead
		panel_pos.x = button_global_pos.x + button_size.x - panel_size.x
		# Ensure still within bounds
		panel_pos.x = max(PANEL_HORIZONTAL_MARGIN, panel_pos.x)
	
	# Check if panel would go off-screen vertically
	if panel_pos.y + panel_size.y > viewport_rect.size.y:
		# Position above button instead
		panel_pos.y = button_global_pos.y - panel_size.y - PANEL_VERTICAL_GAP
		
	# Final boundary check
	panel_pos.x = max(PANEL_HORIZONTAL_MARGIN, min(panel_pos.x, viewport_rect.size.x - panel_size.x - PANEL_HORIZONTAL_MARGIN))
	panel_pos.y = max(PANEL_HORIZONTAL_MARGIN, min(panel_pos.y, viewport_rect.size.y - panel_size.y - PANEL_HORIZONTAL_MARGIN))
	
	domain_panel.position = get_window().position + panel_pos

func _rebuild_domain_list() -> void:
	# Clear existing domain items
	_clear_domain_items()
	
	# Create new domain items
	for domain_name in _all_domains:
		var is_enabled: bool = _enabled_domains.has(domain_name)
		_add_domain_item(domain_name, is_enabled)
	
	_update_panel_size()

func _clear_domain_items() -> void:
	for item in _domain_items:
		if is_instance_valid(item):
			item.queue_free()
	_domain_items.clear()
	
	# Clear any remaining children
	for child in domain_list.get_children():
		child.queue_free()

func _add_domain_item(domain_name: String, is_enabled: bool) -> void:
	var item: DomainItem = DomainItemScene.instantiate()
	
	# Add to scene first
	domain_list.add_child(item)
	_domain_items.append(item)
	
	# Set color manager if available
	if _color_manager:
		item.set_color_manager(_color_manager)
	
	# Setup domain after adding to scene tree (ensures _ready is called first)
	item.setup_domain(domain_name, is_enabled)
	
	# Connect signals
	item.selection_changed.connect(_on_domain_item_selection_changed)
	item.only_button_pressed.connect(_on_domain_item_only_pressed)

## Dynamically adjusts panel size based on the number of domain items
##
## Calculates the optimal panel height by summing all component heights (header, 
## selection controls, domain items, footer, and padding). Clamps the result between
## minimum and maximum height constraints to ensure usability and prevent overflow.
func _update_panel_size() -> void:
	if not domain_panel or _domain_items.is_empty():
		return
		
	# Calculate required height based on content
	var required_height: int = PANEL_HEADER_HEIGHT + PANEL_SELECTION_CONTROLS_HEIGHT + (_domain_items.size() * DOMAIN_ITEM_HEIGHT) + PANEL_FOOTER_HEIGHT + PANEL_PADDING
	var final_height: int = clamp(required_height, PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT)
	
	domain_panel.size = Vector2(PANEL_WIDTH, final_height)

func _update_trigger_button_text() -> void:
	if not trigger_button:
		return
		
	var enabled_count: int = _enabled_domains.size()
	var total_count: int = _all_domains.size()
	
	if total_count == 0:
		trigger_button.text = "Domains: None"
		trigger_button.tooltip_text = "No domains available"
	elif enabled_count == total_count:
		trigger_button.text = "Domains: All"
		trigger_button.tooltip_text = "All domains selected (%d)" % total_count
	elif enabled_count == 0:
		trigger_button.text = "Domains: None"
		trigger_button.tooltip_text = "No domains selected"
	elif enabled_count == 1:
		var domain_name: String = _enabled_domains[0]
		var display_name: String = domain_name if not domain_name.is_empty() else "(default)"
		trigger_button.text = "Domains: " + display_name
		trigger_button.tooltip_text = "Selected: " + display_name
	else:
		trigger_button.text = "Domains: %d selected" % enabled_count
		trigger_button.tooltip_text = "%d of %d domains selected" % [enabled_count, total_count]

func _update_domain_items_state() -> void:
	for item in _domain_items:
		if is_instance_valid(item):
			var domain_name: String = item.get_domain_name()
			var is_enabled: bool = _enabled_domains.has(domain_name)
			item.set_selected(is_enabled)

func _on_domain_item_selection_changed(domain_name: String, is_selected: bool) -> void:
	if is_selected and not _enabled_domains.has(domain_name):
		_enabled_domains.append(domain_name)
	elif not is_selected and _enabled_domains.has(domain_name):
		_enabled_domains.erase(domain_name)
	
	# Update UI and emit change immediately
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

func _on_domain_item_only_pressed(domain_name: String) -> void:
	# Clear all selections and select only this domain instantly
	_enabled_domains.clear()
	_enabled_domains.append(domain_name)
	_update_domain_items_state()
	_update_trigger_button_text()
	domains_changed.emit(_enabled_domains)

func _on_panel_about_to_show() -> void:
	_panel_is_open = true
	if trigger_button:
		trigger_button.disabled = true

func _on_panel_hidden() -> void:
	_panel_is_open = false
	if trigger_button:
		trigger_button.disabled = false
