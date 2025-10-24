class_name LoggieConsoleChannel extends LoggieMsgChannel

## Custom Loggie channel that feeds messages directly to the LoggieConsole
## This channel captures all message metadata (level, type, domain, channels, stack info)
## without requiring string parsing


# Reference to the console window that will display messages
var _console_window: LoggieConsole

func _init() -> void:
	ID = "loggie_console"
	# Enable all preprocessing steps to get complete information
	preprocess_flags = (
		LoggieEnums.PreprocessStep.APPEND_TIMESTAMPS |
		LoggieEnums.PreprocessStep.APPEND_DOMAIN_NAME |
		LoggieEnums.PreprocessStep.APPEND_CLASS_NAME
	)

## Sets the console window that will receive messages from this channel
## @param window: The console window instance, must not be null
func set_console_window(window: LoggieConsole) -> void:
	if window == null:
		Loggie.msg("Cannot set null console window").domain(LoggieConsoleConstants.DOMAIN).error()
		return
	_console_window = window

## Override send method to pass complete message data to console
## @param msg: The Loggie message object containing all metadata
## @param msg_type: The message type enum from Loggie
func send(msg: LoggieMsg, msg_type: LoggieEnums.MsgType) -> void:
	if _console_window == null:
		Loggie.msg("No console window set, message dropped").domain(LoggieConsoleConstants.DOMAIN).warn()
		return
	
	if msg == null:
		Loggie.msg("Received null message").domain(LoggieConsoleConstants.DOMAIN).error()
		return
	
	# Get the preprocessed text (already formatted by Loggie)
	var preprocessed_text = msg.last_preprocess_result
	
	# Determine log level from the message content patterns or message type
	var log_level = _determine_log_level(msg, msg_type)
	
	# Send complete message data to console
	_console_window.receive_log_message(msg, preprocessed_text, msg_type, log_level)

## Determines and returns the [enum LoggieEnums.LogLevel] of a [LoggieMsg] that was sent to this channel.
func _determine_log_level(msg: LoggieMsg, msg_type: LoggieEnums.MsgType) -> LoggieEnums.LogLevel:
	# Loggie 3.0 added a property to [LoggieMsg] that directly stores the log_level as an integer.
	# Check if that property exists and if so, directly convert the integer to the enum and return it.
	if "last_outputted_at_log_level" in msg:
		var log_level_int : int = msg.get("last_outputted_at_log_level")

		if log_level_int == -1: # Message was never outputted yet (Shouldn't be possible, but just in case default to INFO??)
			return LoggieEnums.LogLevel.INFO
		else:
			return (log_level_int as LoggieEnums.LogLevel)

	# Since it didn't exist, the user must be running a version of Loggie < 3.0.
	return _determine_log_level_in_old_loggie_version(msg, msg_type)


## Internal method used by [method _determine_log_level].
## Determines and returns the log level of a message by looking at its msg_type and its content.
## This is a legacy fallback for users that are running a version of Loggie < 3.0.
func _determine_log_level_in_old_loggie_version(msg: LoggieMsg, msg_type: LoggieEnums.MsgType) -> LoggieEnums.LogLevel:
	match int(msg_type):
		0:  # Previously known as `MsgType.STANDARD`.
			# Old Loggie didn't differentiate between INFO and NOTICE when it comes to MsgType.
			# Do what we can to determine which one of those it is:
			# Check if the appearance of the message contains a pattern idicating it's using the "notice" format.
			var notice_pattern = Loggie.settings.format_notice_msg.format({"msg": ""})
			if msg.last_preprocess_result.contains(notice_pattern):
				return LoggieEnums.LogLevel.NOTICE
			else:
				return LoggieEnums.LogLevel.INFO
		1: # Previously and currently known as `MsgType.ERROR`.
			return LoggieEnums.LogLevel.ERROR
		2: # Previously known as `MsgType.WARNING`.
			return LoggieEnums.LogLevel.WARN
		3: # Previously and currentlyknown as `MsgType.DEBUG`.
			return LoggieEnums.LogLevel.DEBUG
		_:
			return LoggieEnums.LogLevel.INFO
