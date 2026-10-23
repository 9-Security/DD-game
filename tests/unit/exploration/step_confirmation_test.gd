extends GdUnitTestSuite
# Unit tests for which chapter actions ask the player to confirm: unsafe actions, and steps that carry
# a blood-curse risk. Plain steps do not ask.

const SEQUENCE: Dictionary = {
	"id": "seal_test",
	"requires": "",
	"steps": [
		{"action": "risky:act", "flag": "risky_done"},
		{"action": "plain:act", "flag": "plain_done"},
	],
	"unsafe": ["danger:act"],
	"curse_risk": {"character": "freya", "per_stack": 0.1, "max": 0.4, "actions": ["risky:act"], "text": "x"},
	"failure": {"text": "x", "segments": 0},
}


func _flow() -> DayOneFlow:
	return DayOneFlow.new([{"id": "freya", "name": "f", "atk": 10, "curse": true}], [0.0], {"sequences": [SEQUENCE]})


func test_an_unsafe_action_needs_confirmation() -> void:
	assert_bool(_flow().needs_confirmation("danger:act")).is_true()


func test_a_plain_step_needs_no_confirmation() -> void:
	assert_bool(_flow().needs_confirmation("plain:act")).is_false()


func test_a_curse_risk_step_needs_confirmation_only_when_the_risk_is_above_zero() -> void:
	var flow := _flow()
	assert_bool(flow.needs_confirmation("risky:act")).is_false()

	flow.finish_battle("lost", {"freya": 2})

	assert_bool(flow.needs_confirmation("risky:act")).is_true()


func test_an_unrelated_action_needs_no_confirmation() -> void:
	assert_bool(_flow().needs_confirmation("move")).is_false()


func test_is_unsafe_names_only_the_unsafe_actions() -> void:
	var flow := _flow()

	assert_bool(flow.is_unsafe_action("danger:act")).is_true()
	assert_bool(flow.is_unsafe_action("risky:act")).is_false()
