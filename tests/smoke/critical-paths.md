# Smoke Test: Critical Paths

**Purpose**: Run these 10-15 checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (which reads this file)
**Update**: Add new entries when new core systems are implemented.

## Core Stability (always run)

1. Game launches to the title screen without crash
2. A new game can be started from the title screen
3. The title screen responds to all inputs without freezing

## Core Mechanic (update per sprint)

4. [Chapter 1 flow: prologue dialogue → day 1 exploration → one battle → day 1 end event]

## Data Integrity

5. Save game completes without error (once save system is implemented)
6. Load game restores correct state (once load system is implemented)

## Performance

7. No visible frame rate drops on the target browser (60 fps target)
8. No memory growth over 5 minutes of play (once the core loop is implemented)
