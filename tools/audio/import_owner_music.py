"""Copies the owner's music from Audio_music/ (which Godot ignores) into assets/audio/music/owner/ so the game can
play it (AUDIO_DESIGN.md §10). Audio is git-ignored: run this after a fresh clone, and after adding a track.
    python tools/audio/import_owner_music.py
The MusicTrack files in data/audio/music/ point at these copies and hold the loop points.
"""
import os
import shutil

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SOURCE = os.path.join(ROOT, "Audio_music")
TARGET = os.path.join(ROOT, "assets", "audio", "music", "owner")
# source file → name in the game (snake_case, AUDIO_DESIGN.md §2.1)
TRACKS = {
    "Sunlight_on_Ancient_Stone.mp3": "sunlight_on_ancient_stone.mp3",
    "Tides_of_the_Morning_Shore.mp3": "tides_of_the_morning_shore.mp3",
    "Where_the_Forest_Remembers.mp3": "where_the_forest_remembers.mp3",
    "Edge_Of_The_Blue.mp3": "edge_of_the_blue.mp3",
    "The_Last_Ascent.mp3": "the_last_ascent.mp3",
    "The_World_Holds_Its_Breath.mp3": "the_world_holds_its_breath.mp3",
}


def main():
    os.makedirs(TARGET, exist_ok=True)
    for source, name in TRACKS.items():
        path = os.path.join(SOURCE, source)
        if not os.path.exists(path):
            print("missing:", source)
            continue
        shutil.copy2(path, os.path.join(TARGET, name))
        print("copied:", name)


if __name__ == "__main__":
    main()
