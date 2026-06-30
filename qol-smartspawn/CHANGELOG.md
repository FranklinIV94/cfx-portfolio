# Changelog

All notable changes to SmartSpawn will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-30

### Added
- Initial release of SmartSpawn
- Tiered permission system (Admin, VIP, Default) via ACE permissions
- Per-player anti-abuse cooldowns with configurable durations
- Vehicle model validation (checks model exists in CDimage before spawning)
- Category-based vehicle restrictions per tier
- Vehicle blocklist for hard-restricted models
- No-spawn zones with configurable radius
- Max vehicles per player limit (prevents entity flooding)
- Previous vehicle cleanup on new spawn
- Auto-seat player into spawned vehicle
- Multi-language support (English, Spanish)
- ox_lib integration with native fallback
- Clean vehicle spawning with proper model loading and cleanup
- State bag tracking for spawned vehicles
- Server exports for cross-resource integration
- Admin command `/spawnclear` for cooldown management
- Comprehensive documentation (README, User Guide, Changelog)
- MIT License