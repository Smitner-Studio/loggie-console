class_name LoggieConsoleChannel extends LoggieMsgChannel

## Custom Loggie channel that feeds messages directly to the LoggieConsole
## This channel captures all message metadata (level, type, domain, channels, stack info)
## without requiring string parsing

const LoggieEnums = preload("res://addons/loggie/tools/loggie_enums.gd")
const LoggieConsoleConstants = preload("res://addons/loggie-console/scripts/loggie_console_constants.gd")


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
	var log_level = _determine_log_level(msg, msg_type, preprocessed_text)
	
	# Send complete message data to console
	_console_window.receive_log_message(msg, preprocessed_text, msg_type, log_level)

## Determine the log level based on message type and content
func _determine_log_level(_msg: LoggieMsg, msg_type: LoggieEnums.MsgType, content: String) -> LoggieEnums.LogLevel:
	# Use message type to infer log level
	match msg_type:
		LoggieEnums.MsgType.ERROR:
			return LoggieEnums.LogLevel.ERROR
		LoggieEnums.MsgType.WARNING:
			return LoggieEnums.LogLevel.WARN
		LoggieEnums.MsgType.DEBUG:
			return LoggieEnums.LogLevel.DEBUG
		LoggieEnums.MsgType.STANDARD:
			# For standard messages, check content patterns to determine level
			if content.contains("[NOTICE]"):
				return LoggieEnums.LogLevel.NOTICE
			else:
				return LoggieEnums.LogLevel.INFO
		_:
			return LoggieEnums.LogLevel.INFO
