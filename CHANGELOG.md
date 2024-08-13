# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2024-08-13
### Fixed
- Fixed manifest discovery error with multiple manifests. Manifests are now discovered based
  on priority basis as follows:
   1. `rokit.toml`
   2. `aftman.toml`
   3. `foreman.toml`

## [0.1.1] - 2024-08-10
### Changed
- Now uses the official installer script internally for installing Rokit
- Used `authenticate` command instead of manually writing file

## [0.1.0] - 2024-08-04
### Added
- Initial release, with support for rokit instead of aftman

[Unreleased]: https://github.com/CompeyDev/setup-rokit/compare/v0.1.2...HEAD
[0.1.0]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.0
[0.1.1]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.1
[0.1.2]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.2
