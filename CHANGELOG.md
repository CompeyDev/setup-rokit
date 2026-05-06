# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.1] - 2026-05-06
### Fixed
- Install step always failing outside repo CI due to install script never being in path

## [0.2.0] - 2026-05-04
### Breaking Changes
- Updated `actions/cache` dependency to v5, requiring at least node v24 and actions runner v2.327.1
### Added
- Fuzzy semver matching: versions such as v1, v1.1, etc. will get resolved to the latest matching
  semver version
- 'v' prefixes are optionally accepted in the version input
- Comprehensive test cases for installation and version resolution
### Fixed
- The version input is actually respected, it was previously ignored and defaulted to the latest release

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

[Unreleased]: https://github.com/CompeyDev/setup-rokit/compare/v0.2.1...HEAD
[0.1.0]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.0
[0.1.1]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.1
[0.1.2]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.1.2
[0.2.0]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.2.0
[0.2.1]: https://github.com/CompeyDev/setup-rokit/releases/tag/v0.2.1
