# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.1] - 2025-08-31

### Added
- Plugin system with automatic autoload setup (LoggieConsole singleton)
- Automatic plugin installation through Godot's plugin system

### Changed
- Removed @tool directive from component scripts for better runtime performance
- Simplified installation process - now uses Godot's plugin system

### Fixed
- Fixed null message exception in log buffer filtering (`log_buffer.gd:132`)
- Improved null-safety in `_reapply_filters()` method

## [1.0.0] - 2025-08-31

### Added
- Interactive debug console for Godot 4.4
- Multi-domain filtering with color-coded visualization
- Real-time search functionality for log messages
- Persistent settings for window position, filters, and preferences
- Flexible display options (standalone window or embedded)
- Component-based architecture with modular UI components
- LogBuffer for efficient message storage and filtering
- PanelDomainSelector for advanced domain filtering
- LogLevelFilter for log level selection (ERROR, WARN, INFO, DEBUG)
- ConsoleControls with action buttons, search, and settings
- StatusDisplay showing statistics and status information
- Custom Loggie channel integration for complete message metadata
- Multi-display support with window positioning validation
- Test scene demonstrating console functionality
- Automatic settings persistence on window close/minimize
- Performance optimizations for high-volume logging

### Dependencies
- Requires Loggie 2.x logging framework
- Compatible with Godot 4.4+

[Unreleased]: https://github.com/Smitner-Studio/loggie-console/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/Smitner-Studio/loggie-console/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/Smitner-Studio/loggie-console/releases/tag/v1.0.0