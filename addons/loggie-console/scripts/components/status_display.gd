class_name StatusDisplay extends Label

## Standalone status display component for console information
## Shows message counts, filter status, and real-time feedback

func _ready() -> void:
	text = "Ready"
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

## Update status with message and domain information
func update_status(total_messages: int, filtered_messages: int, enabled_domains: Array[String], total_domains: int) -> void:
	var status_text = ""
	
	if total_messages == 0:
		status_text = "Ready"
	else:
		# Message count display
		if filtered_messages == total_messages:
			status_text = "%d msgs" % total_messages
		else:
			status_text = "%d/%d msgs" % [filtered_messages, total_messages]
		
		# Domain filter info
		if total_domains > 0 and enabled_domains.size() < total_domains:
			status_text += " | %d/%d domains" % [enabled_domains.size(), total_domains]
	
	text = status_text

## Update status when only message counts change (simpler version)
func update_message_counts(total_messages: int, filtered_messages: int) -> void:
	if total_messages == 0:
		text = "Ready"
	elif filtered_messages == total_messages:
		text = "%d msgs" % total_messages
	else:
		text = "%d/%d msgs" % [filtered_messages, total_messages]

## Show search status when text filtering is active
## @param search_term: Current search filter text
## @param results_count: Number of messages matching the search
## @param total_count: Total number of messages in buffer
func update_search_status(search_term: String, results_count: int, total_count: int) -> void:
	if search_term.is_empty():
		update_message_counts(total_count, results_count)
	else:
		text = "Search: \"%s\" - %d/%d msgs" % [search_term, results_count, total_count]

## Show loading/processing status with operation name
## @param operation: Name of the operation being performed
func show_processing_status(operation: String) -> void:
	text = "%s..." % operation

## Reset to ready state
func reset() -> void:
	text = "Ready"
