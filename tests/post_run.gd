extends GutHookScript
## Runs after all tests (.gutconfig.json): silences every sound and gives the audio thread a moment, so no
## playback is still alive when GUT quits (otherwise "resources still in use at exit" is printed). Silences twice:
## a timer from the last tests (a stinger, a cutscene effect) may start a sound during the first wait.


func run() -> void:
	AudioManager.silence()
	await gut.get_tree().create_timer(0.6).timeout
	AudioManager.silence()
	await gut.get_tree().create_timer(0.3).timeout
