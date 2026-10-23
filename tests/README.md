# Test Infrastructure

**Engine**: Godot 4.7.2
**Test Framework**: GdUnit4 6.2.2 (vendored in `addons/gdUnit4/`)
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-10-23

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
```

```
production/qa/
  evidence/       # Screenshot logs and manual test sign-off records
```

> Manual evidence lives under `production/qa/evidence/`, not `tests/`.

## Running Tests

Import the project first. A fresh clone has no `.godot/` class cache, and
a run without one exits 1 with no tests executed.

```bash
godot --headless --path . --import
godot --headless -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests --ignoreHeadlessMode
```

Exit codes:

| Code | Meaning |
|---|---|
| 0 | All tests passed. With no tests found it also exits 0, which is **not** a pass |
| 100 | At least one test failed |
| 101 | All passed, but a test leaked nodes (warning) |
| 103 / 104 | GdUnit4 could not run |
| 105 | A test script does not parse |

The `ERROR:` lines about `127.0.0.1:0` are expected when `--remote-debug` is used.

## Test Naming

- File: `[system]_[feature]_test.gd`
- Function: `test_[scenario]_[expected]()`
- Example: `combat_damage_test.gd` → `test_base_attack_returns_expected_damage()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Integration test OR playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Retained screenshot of each screen touched | `production/qa/evidence/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run on every push to `main` and on every pull request. A failed test
suite blocks merging. The CI job uses the vendored addon (`version: installed`)
and Godot 4.7.2.
