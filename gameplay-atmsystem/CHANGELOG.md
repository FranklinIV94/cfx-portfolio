# Changelog

All notable changes to ATM System will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-30

### Added
- Initial release of ATM System
- Dual currency system (bank balance + wallet cash)
- ATM prop interaction with [E] key detection
- ox_lib context menu UI with native notification fallback
- Withdrawal and deposit functionality
- Player-to-player bank transfers with configurable fees
- In-person cash giving with proximity check
- ATM withdrawal fees
- Transaction history with full logging
- Interest system with configurable rate and interval
- Overdraft protection with configurable limit
- Anti-abuse cooldowns and rate limiting
- Dual storage: JSON file (default) and oxmysql (database)
- Bank blips on the minimap
- Admin commands: `/bank` (view balance), `/setmoney` (set balance)
- ACE permission integration for admin access
- Multi-language support (English, Spanish)
- Server-side exports for cross-resource integration (addMoney, removeMoney, getBalance, getHistory)
- Comprehensive documentation (README, User Guide, Changelog)
- SQL schema for oxmysql mode
- MIT License