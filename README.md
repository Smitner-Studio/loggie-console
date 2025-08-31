![LoggieConsole.PNG](assets/loggie-console-logo.png)
# Loggie Console

An interactive debug console for Godot 4.4. Built on top of [Loggie](https://github.com/Shiva-Shadowsong/loggie) with filtering, search, and multi-display support.

## Key Features

- **Multi-domain filtering**: Organize logs by system (Audio, Physics, AI, etc.) with color-coded visualization
- **Real-time search**: Find specific messages instantly across thousands of log entries
- **Persistent settings**: Window position, filters, and preferences saved across sessions
- **Flexible display options**: Run as standalone window or embedded in your game

## Install

1. Install [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie).
2. Implement [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) into your project. (Read the [User Guide](https://github.com/Shiva-Shadowsong/loggie/blob/main/docs/USER_GUIDE.md))
3. Put the contents of this repository's `./addons` directory into your Godot project.
4. Do one of the following:
   - Create an autoload of the Console scene `res://addons/loggie-console/scenes/console.tscn`.
   - Instantiate the `res://addons/loggie-console/scenes/console.tscn` scene where appropriate.

## Development

### Prerequisites

- Godot 4.4+
- [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) logging framework

### Setup

1. Clone this repository
2. **Important**: Manually install [Loggie 2.x](https://github.com/Shiva-Shadowsong/loggie) into the `addons/loggie/` directory
3. Open `project.godot` in Godot 4.4
4. Run the console scene directly or integrate into your project

The Loggie dependency is not included in this repository and must be installed separately following the [Loggie installation guide](https://github.com/Shiva-Shadowsong/loggie/blob/main/docs/USER_GUIDE.md).

### Demo

The project includes a test scene that demonstrates the console functionality. Run `res://test/loggie_test.tscn` to see an interactive demo with buttons to generate different types of log messages, test continuous logging, and demonstrate filtering, domain organization, and search capabilities.

## Example
![capture.PNG](assets/capture.PNG)
