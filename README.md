![LoggieConsole.PNG](assets/loggie-console-logo.png)
# Loggie Console

An interactive debug console for Godot 4.4. Built on top of [Loggie](https://github.com/Shiva-Shadowsong/loggie) with filtering, search, and flexible display support.

## Key Features

- **Multi-domain filtering**: Organize logs by system (Audio, Physics, AI, etc.) with color-coded visualization
- **Real-time search**: Find specific messages instantly across thousands of log entries
- **Persistent settings**: Window position, filters, and preferences saved across sessions
- **Flexible display options**: Run as standalone window or embedded in your game

![capture.PNG](assets/capture.PNG)

## Install

### Prerequisites
- Godot 4.4+
- [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) logging framework

### Installation Steps

1. **Install Loggie first**: Follow the [Loggie installation guide](https://github.com/Shiva-Shadowsong/loggie/blob/main/docs/USER_GUIDE.md) to add Loggie to your project
2. **Download the addon**: Download the latest release from the [releases page](https://github.com/Smitner-Studio/loggie-console/releases)
3. **Extract to your project**: Extract the `loggie-console/` folder into your Godot project's `addons/` directory
4. **Enable the plugin**: In Godot, go to Project Settings → Plugins and enable "Loggie Console"

Once enabled, the console will be automatically added as an autoload singleton named `LoggieConsole` and will be accessible throughout your project.

## Usage

Once installed, the console can be accessed in several ways:

- **Global access**: Use `LoggieConsole` singleton from anywhere in your code
- **Toggle visibility**: The console window can be shown/hidden as needed
- **Scene integration**: The console automatically integrates with Loggie's logging system

### Example Usage

```gdscript
# The console is automatically available as LoggieConsole
# It will receive all log messages sent through Loggie

# Example logging that will appear in the console
Loggie.info("Game started", "GameManager")
Loggie.warn("Low health warning", "Player") 
Loggie.error("Failed to load save file", "SaveSystem")
```

## Development

### Prerequisites

- Godot 4.4+
- [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) logging framework

### Development Setup

1. Clone this repository
2. **Important**: Manually install [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) into the `addons/loggie/` directory
3. Open `project.godot` in Godot 4.4
4. Enable both "Loggie" and "Loggie Console" plugins in Project Settings → Plugins

The Loggie dependency is not included in this repository and must be installed separately following the [Loggie installation guide](https://github.com/Shiva-Shadowsong/loggie/blob/main/docs/USER_GUIDE.md).

### Demo

The project includes a test scene that demonstrates the console functionality. Run `res://test/loggie_test.tscn` to see an interactive demo with buttons to generate different types of log messages, test continuous logging, and demonstrate filtering, domain organization, and search capabilities.

