@tool
class_name LogBuffer extends RichTextLabel

## Enhanced message buffer with retroactive filtering capabilities
## Stores all messages and applies filters dynamically without losing data

const LoggieConsoleSettings = preload("res://addons/loggie-console/resources/loggie_console_settings.gd")
const DomainColorManager = preload("res://addons/loggie-console/scripts/domain_color_manager.gd")

# Signals
signal filter_changed(visible_count: int, total_count: int)

# Internal message storage
var _all_messages: Array[LogMessage] = []
var _filtered_messages: Array[LogMessage] = []
var _current_filters: FilterState

# Domain color manager reference
var _color_manager: DomainColorManager

# Memory management constants
const DEFAULT_MAX_MESSAGES: int = 5000
const CLEANUP_PERCENTAGE: float = 0.2  # Remove 20% of messages when limit reached

# Memory management
@export var max_messages: int = DEFAULT_MAX_MESSAGES

## Internal LogMessage class for storing complete message data
class LogMessage:
	var msg: LoggieMsg
	var preprocessed_content: String
	var msg_type: LoggieEnums.MsgType
	var log_level: LoggieEnums.LogLevel
	var timestamp: float
	var enhanced_content: String
	
	func _init(p_msg: LoggieMsg, p_content: String, p_type: LoggieEnums.MsgType, p_level: LoggieEnums.LogLevel) -> void:
		msg = p_msg
		preprocessed_content = p_content
		msg_type = p_type
		log_level = p_level
		timestamp = Time.get_unix_time_from_system()

## Filter state for retroactive filtering
class FilterState:
	var enabled_domains: Array[String] = []
	var min_log_level: LoggieEnums.LogLevel = LoggieEnums.LogLevel.DEBUG
	var text_search: String = ""
	var show_stack_only: bool = false
	
	func _init() -> void:
		# Initialize to show ERROR and above by default (lower numbers = higher priority)
		min_log_level = LoggieEnums.LogLevel.DEBUG

func _ready() -> void:
	_current_filters = FilterState.new()
	bbcode_enabled = true

## Set the domain color manager instance
func set_color_manager(color_manager: DomainColorManager) -> void:
	_color_manager = color_manager

## Add a new log message to the buffer
func add_message(msg: LoggieMsg, content: String, msg_type: LoggieEnums.MsgType, log_level: LoggieEnums.LogLevel) -> void:
	# Create and store the message
	var log_msg: LogMessage = LogMessage.new(msg, content, msg_type, log_level)
	log_msg.enhanced_content = _enhance_with_metadata(log_msg)
	
	_all_messages.append(log_msg)
	
	# Manage memory if needed
	_manage_memory()
	
	# Apply current filters and rebuild display
	_reapply_filters()

## Set new filter state and reapply filters
func set_filters(filter_state: FilterState) -> void:
	_current_filters = filter_state
	_reapply_filters()

## Set text search filter
func set_text_search(search: String) -> void:
	if _current_filters.text_search == search:
		return
	
	_current_filters.text_search = search
	_reapply_filters()

## Clear all messages
func clear_all() -> void:
	_all_messages.clear()
	_filtered_messages.clear()
	text = ""
	clear()
	
	# Emit updated counts
	filter_changed.emit(0, 0)

## Get current message counts
func get_message_counts() -> Dictionary:
	return {
		"total": _all_messages.size(),
		"filtered": _filtered_messages.size()
	}

## Saves current buffer state to persistent settings resource
## Param settings: The settings resource to populate with current state
func save_settings_to_resource(settings: LoggieConsoleSettings) -> void:
	settings.filter_state.from_filter_state(_current_filters)
	settings.max_messages = max_messages

## Loads buffer state from persistent settings resource
## Note: Does not immediately apply filters to avoid triggering reapply before messages exist
## Param settings: The settings resource containing saved state
func load_settings_from_resource(settings: LoggieConsoleSettings) -> void:
	if settings.filter_state:
		_current_filters = settings.filter_state.to_filter_state()
	max_messages = settings.max_messages

## Applies previously loaded filter state to existing messages
## Call this after load_settings_from_resource() and message loading is complete
func apply_loaded_filters() -> void:
	_reapply_filters()


## Private methods

func _reapply_filters() -> void:
	_filtered_messages.clear()
	
	for msg in _all_messages:
		if msg and _message_passes_filters(msg, _current_filters):
			_filtered_messages.append(msg)
	
	_rebuild_display()
	
	# Emit filter change signal
	filter_changed.emit(_filtered_messages.size(), _all_messages.size())

func _message_passes_filters(msg: LogMessage, filters: FilterState) -> bool:
	# Domain check - if no domains are enabled, show no messages
	if filters.enabled_domains.size() == 0:
		return false
	
	# If domains are enabled, check if this message's domain is in the enabled list
	if not filters.enabled_domains.has(msg.msg.domain_name):
		return false
	
	# Level check - show messages at or above the minimum level (lower numbers = higher priority)
	if msg.log_level > filters.min_log_level:
		return false
	
	# Text search
	if not filters.text_search.is_empty():
		var search_lower: String = filters.text_search.to_lower()
		if not msg.preprocessed_content.to_lower().contains(search_lower):
			return false
	
	# Stack filter
	if filters.show_stack_only and not msg.msg.appends_stack:
		return false
	
	return true

func _rebuild_display() -> void:
	# Clear current display
	text = ""
	clear()
	
	# Add all filtered messages
	for msg in _filtered_messages:
		text += msg.enhanced_content + "\n"

func _enhance_with_metadata(msg: LogMessage) -> String:
	var metadata_parts: Array[String] = []
	
	metadata_parts.append("[color=%s]%s [/color]" % [Color.DIM_GRAY.to_html(false), Time.get_time_string_from_unix_time(int(msg.timestamp))])
	
	if msg.msg.domain_name and not msg.msg.domain_name.is_empty():
		var domain_color_html: String = _color_manager.get_domain_color_html(msg.msg.domain_name)
		metadata_parts.append("[color=%s]%s[/color]" % [domain_color_html, msg.msg.domain_name])
		
	if msg.msg.domain_name and not msg.msg.domain_name.is_empty():
		metadata_parts.append("[color=%s][%s] [/color]" % [_get_color_for_log_level(msg.log_level).to_html(false), LoggieEnums.LogLevel.keys()[msg.log_level]])
	
	return "%s %s" % [" ".join(metadata_parts), msg.msg.content[0]]
	
func _get_color_for_log_level(level: LoggieEnums.LogLevel) -> Color:
	match level:
		LoggieEnums.LogLevel.ERROR:
			return Color.RED
		LoggieEnums.LogLevel.WARN:
			return Color.ORANGE
		LoggieEnums.LogLevel.NOTICE:
			return Color.GREEN
		LoggieEnums.LogLevel.INFO:
			return Color.WHITE
		LoggieEnums.LogLevel.DEBUG, _:
			return Color.AQUA

## Manages memory by removing oldest messages when buffer limit exceeded
## Uses CLEANUP_PERCENTAGE constant to determine how many messages to remove
func _manage_memory() -> void:
	if _all_messages.size() > max_messages:
		# Remove oldest messages based on cleanup percentage
		var remove_count: int = int(max_messages * CLEANUP_PERCENTAGE)
		_all_messages = _all_messages.slice(remove_count)
		# Note: This will cause filtered_messages indices to be invalid, 
		# but _reapply_filters() will be called which rebuilds it
