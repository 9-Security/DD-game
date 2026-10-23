class_name DayClock
extends RefCounted
## Tracks the seven-day time limit in three segments per day (morning, noon, night).
## Time is spent through spend(); the clock reports how many day-end boundaries
## were crossed so the caller can trigger the day-end event.

const SEGMENTS_PER_DAY: int = 3
const TOTAL_DAYS: int = 7
const SEGMENT_MORNING: int = 0
const SEGMENT_NOON: int = 1
const SEGMENT_NIGHT: int = 2

var day: int = 1
var segment: int = SEGMENT_MORNING

## Total segments spent since the start of day one.
var _elapsed: int = 0


## Returns true once the seventh day's night segment has been spent.
func is_expired() -> bool:
	return _elapsed >= TOTAL_DAYS * SEGMENTS_PER_DAY


## Total segments spent so far. Used when saving the game.
func get_elapsed() -> int:
	return _elapsed


## Restores the clock to a saved elapsed value.
## Returns false and changes nothing when the value is outside the seven-day range.
func restore_elapsed(elapsed: int) -> bool:
	if elapsed < 0 or elapsed > TOTAL_DAYS * SEGMENTS_PER_DAY:
		return false
	_elapsed = elapsed
	_sync_position()
	return true


## Spends the given number of segments.
## Returns the number of day-end boundaries crossed (night finished).
## Non-positive costs and spending after expiry are ignored and return 0.
func spend(cost: int) -> int:
	if cost <= 0 or is_expired():
		return 0

	var previous_elapsed: int = _elapsed
	_elapsed = mini(_elapsed + cost, TOTAL_DAYS * SEGMENTS_PER_DAY)
	_sync_position()

	@warning_ignore("integer_division")
	var boundaries: int = _elapsed / SEGMENTS_PER_DAY - previous_elapsed / SEGMENTS_PER_DAY
	return boundaries


## Derives the displayed day and segment from the elapsed total.
func _sync_position() -> void:
	if is_expired():
		day = TOTAL_DAYS
		segment = SEGMENT_NIGHT
	else:
		@warning_ignore("integer_division")
		day = _elapsed / SEGMENTS_PER_DAY + 1
		segment = _elapsed % SEGMENTS_PER_DAY
