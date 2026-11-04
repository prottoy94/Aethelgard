extends GutHookScript
## Runs after all tests (.gutconfig.json): silences every sound and gives the audio thread a moment, so no
## playback is still alive when GUT quits (otherwise "resources still in use at exit" is printed).


func run() -> void:
	AudioManager.silence()
	await gut.get_tree().create_timer(0.3).timeout
