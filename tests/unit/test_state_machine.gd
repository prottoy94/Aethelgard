extends GutTest
## StateMachine: starts in the initial state, transitions call exit/enter and emit state_changed.


class Recorder:
	extends State
	var log: Array[String] = []

	func enter(previous: StringName, _data: Dictionary) -> void:
		log.append("enter %s<-%s" % [name, previous])

	func exit() -> void:
		log.append("exit %s" % name)


func _make_machine() -> StateMachine:
	var owner_node: Node = Node.new()
	var machine := StateMachine.new()
	for state_name: String in ["A", "B"]:
		var s := Recorder.new()
		s.name = state_name
		machine.add_child(s)
	machine.initial_state = machine.get_node("A")
	owner_node.add_child(machine)
	add_child_autofree(owner_node)
	return machine


func test_starts_in_initial_state() -> void:
	var machine := _make_machine()
	assert_true(machine.is_in(&"A"))
	assert_eq((machine.get_node("A") as Recorder).log, ["enter A<-"] as Array[String])
	assert_eq((machine.get_node("A") as State).actor, machine.get_parent(), "actor is the machine's parent")


func test_transition_calls_exit_enter_and_signals() -> void:
	var machine := _make_machine()
	watch_signals(machine)
	machine.transition_to(&"B")
	assert_true(machine.is_in(&"B"))
	assert_has((machine.get_node("A") as Recorder).log, "exit A")
	assert_has((machine.get_node("B") as Recorder).log, "enter B<-A")
	assert_signal_emitted_with_parameters(machine, "state_changed", [&"A", &"B"])
