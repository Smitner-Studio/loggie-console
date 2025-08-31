extends Node2D

## Test script for generating various Loggie log messages
## Tests different domains, log levels, message types, and content formats

# Domain constants
const DOMAIN_DEFAULT: StringName = &""
const DOMAIN_TEST_RUNNER: StringName = &"TEST_RUNNER"
const DOMAIN_GAME_LOGIC: StringName = &"GAME_LOGIC"
const DOMAIN_AUDIO_SYSTEM: StringName = &"AUDIO_SYSTEM"
const DOMAIN_NETWORK: StringName = &"NETWORK"
const DOMAIN_UI_MANAGER: StringName = &"UI_MANAGER"
const DOMAIN_PHYSICS: StringName = &"PHYSICS"
const DOMAIN_SAVE_SYSTEM: StringName = &"SAVE_SYSTEM"
const DOMAIN_LOCALIZATION: StringName = &"LOCALIZATION"

# Timing constants
const LOG_INTERVAL: float = 0.5  # Log every 500ms

# Test data arrays
const LOG_LEVELS: Array[String] = ["Poor", "Fair", "Good", "Excellent"]
const BUTTON_NAMES: Array[String] = ["Start", "Options", "Quit", "Inventory"]
const DIALOG_NAMES: Array[String] = ["Settings", "Inventory", "Map", "Help"]
const LANGUAGE_CODES: Array[String] = ["EN", "ES", "FR", "DE"]
const LANGUAGE_NAMES: Array[String] = ["English", "Spanish", "French", "German"]

var _logging_timer: Timer
var _test_counter: int = 0
var _domains: Array[StringName] = [
	DOMAIN_DEFAULT,
	DOMAIN_GAME_LOGIC,
	DOMAIN_AUDIO_SYSTEM,
	DOMAIN_NETWORK,
	DOMAIN_UI_MANAGER,
	DOMAIN_PHYSICS,
	DOMAIN_SAVE_SYSTEM,
	DOMAIN_LOCALIZATION
]

func _ready() -> void:
	# Initialize logging timer
	_logging_timer = Timer.new()
	_logging_timer.wait_time = LOG_INTERVAL
	_logging_timer.timeout.connect(_on_logging_timer_timeout)
	add_child(_logging_timer)
	
	# Create some initial domains in Loggie
	_setup_loggie_domains()
	
	Loggie.msg("=== Loggie Console Test Scene Started ===").domain(DOMAIN_TEST_RUNNER).info()
	Loggie.msg("Use the buttons to generate different types of log messages").domain(DOMAIN_TEST_RUNNER).notice()

func _setup_loggie_domains() -> void:
	# Enable all test domains in Loggie
	for domain in _domains:
		if not domain.is_empty():
			Loggie.set_domain_enabled(domain, true)

func _on_start_logs_pressed() -> void:
	if _logging_timer.is_stopped():
		_logging_timer.start()
		Loggie.msg("Started continuous logging timer").domain(DOMAIN_TEST_RUNNER).info()
	else:
		Loggie.msg("Logging timer already running").domain(DOMAIN_TEST_RUNNER).warn()

func _on_single_test_pressed() -> void:
	_generate_test_burst()

func _on_error_test_pressed() -> void:
	_generate_error_scenarios()

func _on_clear_pressed() -> void:
	_logging_timer.stop()
	Loggie.msg("Stopped all logging timers").domain(DOMAIN_TEST_RUNNER).notice()

func _on_logging_timer_timeout() -> void:
	_test_counter += 1
	_generate_varied_logs()

func _generate_test_burst() -> void:
	Loggie.msg("=== Starting Single Test Burst ===").domain(DOMAIN_TEST_RUNNER).notice()
	
	# Test basic log levels with default domain
	Loggie.msg("This is a debug message").debug()
	Loggie.msg("This is an info message").info()
	Loggie.msg("This is a notice message").notice()
	Loggie.msg("This is a warning message").warn()
	Loggie.msg("This is an error message").error()
	
	# Test different domains
	Loggie.msg("Game state initialized successfully").domain(DOMAIN_GAME_LOGIC).info()
	Loggie.msg("Audio volume adjusted to 75%").domain(DOMAIN_AUDIO_SYSTEM).debug()
	Loggie.msg("Network connection established").domain(DOMAIN_NETWORK).notice()
	Loggie.msg("UI element 'MainMenu' loaded").domain(DOMAIN_UI_MANAGER).info()
	
	# Test rich text formatting
	Loggie.msg("Player scored [color=green]1000[/color] points!").domain(DOMAIN_GAME_LOGIC).notice()
	Loggie.msg("[b]Critical error[/b] in save system!").domain(DOMAIN_SAVE_SYSTEM).error()
	Loggie.msg("[i]Loading...[/i] please wait").domain(DOMAIN_UI_MANAGER).info()
	
	# Test multiline messages
	Loggie.msg("""Multiline debug info:
- FPS: 60
- Memory: 128MB
- Entities: 42""").domain(DOMAIN_GAME_LOGIC).debug()
	
	# Test special characters and formatting
	Loggie.msg("Special chars: éñ中文🎮 @#$%^&*()").domain(DOMAIN_LOCALIZATION).debug()
	Loggie.msg("JSON-like: {\"player_id\": 123, \"level\": \"forest\"}").domain(DOMAIN_SAVE_SYSTEM).info()
	
	Loggie.msg("=== Test Burst Complete ===").domain(DOMAIN_TEST_RUNNER).notice()

func _generate_varied_logs() -> void:
	var domain := _domains[_test_counter % _domains.size()]
	var messages := _get_domain_specific_messages(domain)
	var message := messages[randi() % messages.size()]
	
	# Vary log levels based on counter
	match _test_counter % 5:
		0:
			Loggie.msg(message).domain(domain).debug()
		1:
			Loggie.msg(message).domain(domain).info()
		2:
			Loggie.msg(message).domain(domain).notice()
		3:
			Loggie.msg(message).domain(domain).warn()
		4:
			Loggie.msg(message).domain(domain).error()

func _get_domain_specific_messages(domain: StringName) -> Array[String]:
	match domain:
		DOMAIN_DEFAULT:
			return [
				"System tick %d" % _test_counter,
				"Application running smoothly",
				"Memory usage: %d MB" % (64 + (_test_counter % 100)),
				"Frame rendered successfully"
			]
		DOMAIN_GAME_LOGIC:
			return [
				"Player health: %d/100" % (100 - (_test_counter % 50)),
				"Enemy spawned at position (%.1f, %.1f)" % [randf() * 100, randf() * 100],
				"Level progression: %d%%" % (_test_counter % 101),
				"Power-up collected: [color=yellow]Speed Boost[/color]",
				"Game state saved successfully"
			]
		DOMAIN_AUDIO_SYSTEM:
			return [
				"Playing sound: footstep_%d.ogg" % (_test_counter % 4),
				"Background music volume: %d%%" % (50 + (_test_counter % 51)),
				"Audio buffer underrun detected",
				"Sound effect loaded: explosion.wav",
				"Audio device changed to: Default Speakers"
			]
		DOMAIN_NETWORK:
			return [
				"Ping to server: %dms" % (20 + (_test_counter % 200)),
				"Packet sent: %d bytes" % (64 + (_test_counter % 1000)),
				"Connection quality: %s" % (LOG_LEVELS[_test_counter % LOG_LEVELS.size()]),
				"Player joined: User_%d" % (_test_counter % 100),
				"Synchronizing world state..."
			]
		DOMAIN_UI_MANAGER:
			return [
				"Button clicked: %s" % (BUTTON_NAMES[_test_counter % BUTTON_NAMES.size()]),
				"Dialog opened: [i]%s[/i]" % (DIALOG_NAMES[_test_counter % DIALOG_NAMES.size()]),
				"UI animation completed: fade_in",
				"Text localized to: %s" % (LANGUAGE_CODES[_test_counter % LANGUAGE_CODES.size()]),
				"Tooltip displayed: 'Click to continue'"
			]
		DOMAIN_PHYSICS:
			return [
				"Collision detected between Player and Wall",
				"Physics step completed in %.2fms" % (randf() * 5),
				"Rigid body velocity: (%.1f, %.1f)" % [randf() * 10 - 5, randf() * 10 - 5],
				"Gravity applied: -9.81 m/s²",
				"Joint constraint solved"
			]
		DOMAIN_SAVE_SYSTEM:
			return [
				"Auto-save triggered",
				"Save file size: %d KB" % (100 + (_test_counter % 500)),
				"Configuration saved to disk",
				"Backup created: save_%d.dat" % _test_counter,
				"Save data validated successfully"
			]
		DOMAIN_LOCALIZATION:
			return [
				"Language changed to: %s" % (LANGUAGE_NAMES[_test_counter % LANGUAGE_NAMES.size()]),
				"String key missing: 'ui.button.confirm'",
				"Font loaded: NotoSans-Regular.ttf",
				"Text direction set to: LTR",
				"Character encoding: UTF-8"
			]
		_:
			return ["Unknown domain message %d" % _test_counter]

func _generate_error_scenarios() -> void:
	Loggie.msg("=== Generating Error Test Scenarios ===").domain(DOMAIN_TEST_RUNNER).warn()
	
	# Critical system errors
	Loggie.msg("[b]CRITICAL:[/b] Out of memory exception!").domain(DOMAIN_DEFAULT).error()
	Loggie.msg("Failed to load essential resource: player.tscn").domain(DOMAIN_GAME_LOGIC).error()
	Loggie.msg("Network connection lost - server unreachable").domain(DOMAIN_NETWORK).error()
	
	# Stack trace simulation
	Loggie.msg("Stack Trace:").domain(DOMAIN_GAME_LOGIC).error().stack()
	
	# Warnings with potential issues
	Loggie.msg("Low memory warning: %d MB remaining" % (5 + (randi() % 10))).domain(DOMAIN_DEFAULT).warn()
	Loggie.msg("Audio device disconnected, switching to fallback").domain(DOMAIN_AUDIO_SYSTEM).warn()
	Loggie.msg("Save file corrupted, using backup").domain(DOMAIN_SAVE_SYSTEM).warn()
	
	# Long error messages
	var long_error := "A very long error message that contains extensive details about what went wrong, including multiple parameters, stack information, and detailed diagnostic data that should test the console's handling of lengthy log entries and word wrapping capabilities."
	Loggie.msg(long_error).domain(DOMAIN_SAVE_SYSTEM).error()
	
	# Rapid error burst
	for i in range(5):
		Loggie.msg("Rapid error burst #%d - testing console performance" % (i + 1)).domain(DOMAIN_TEST_RUNNER).error()
	
	Loggie.msg("=== Error Scenarios Complete ===").domain(DOMAIN_TEST_RUNNER).warn()
