extends GutTest
## Cooldown: ready/not ready, ticking and progress.


func test_new_cooldown_is_ready() -> void:
	assert_true(Cooldown.new().is_ready())


func test_start_tick_and_ready() -> void:
	var c := Cooldown.new()
	c.start(0.6)
	assert_false(c.is_ready())
	c.tick(0.3)
	assert_almost_eq(c.progress(), 0.5, 0.001)
	c.tick(0.31)
	assert_true(c.is_ready())
	assert_eq(c.remaining, 0.0, "never goes negative")
