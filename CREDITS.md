# Aethelgard — Credits & Asset Sources

Every shipped asset that isn't a generated placeholder gets an entry here (see AUDIO_DESIGN.md §7.3 and REQUIREMENTS.md `NFR-ART-03`, `NFR-AUD-02`).

## Music

| File (source) | Used as | Made by / tool | Licence / terms | Notes |
|---|---|---|---|---|
| `Audio_music/Sunlight_on_Ancient_Stone.mp3` | `mus_title`, `mus_ending_credits`, Aurelia's leitmotif | Project owner, using a Google generative AI tool (❓ which one) | ❓ Owner to confirm the tool's terms allow commercial use | Content credentials: "Created by Google Generative AI"; SynthID watermark. Vocals = Aurelia's voice. |
| `Audio_music/Tides_of_the_Morning_Shore.mp3` | `mus_azure_coast_explore` | Project owner, using a Google generative AI tool (❓ which one) | ❓ Owner to confirm | Content credentials: "Created by Google Generative AI"; SynthID watermark. Instrumental. |
| `Audio_music/Where_the_Forest_Remembers.mp3` | ❓ not decided (not analysed yet) | Project owner, Google generative AI tool (❓ which one) | ❓ Owner to confirm | Added 2026-11-03 |
| `Audio_music/Edge_Of_The_Blue.mp3` | ❓ not decided (not analysed yet) | Project owner, Google generative AI tool (❓) | ❓ Owner to confirm | Added 2026-11-03 |
| `Audio_music/The_Last_Ascent.mp3` | ❓ not decided (not analysed yet) | Project owner, Google generative AI tool (❓) | ❓ Owner to confirm | Added 2026-11-03 |
| `Audio_music/The_World_Holds_Its_Breath.mp3` | ❓ not decided (not analysed yet) | Project owner, Google generative AI tool (❓) | ❓ Owner to confirm | Added 2026-11-03 |

## Animations

| File (source) | Used as | Made by | Licence | Notes |
|---|---|---|---|---|
| `assets/animations/quaternius_ual/AnimationLibrary_Godot_Standard.glb` | All humanoid animations (Aurelia, NPCs) and the grey stand-in mannequin | Quaternius (Universal Animation Library, Standard) | **CC0 1.0** (`License.txt` beside it) | From opengameart.org/content/universal-animation-library, downloaded 2026-11-03. Git-ignored (model file) |

## Sound effects
*(none yet)*

## Art
*(none yet; reference images in `Game Images/` are not shipped assets)*

## Code / add-ons
| Add-on | Version | Author | Licence | Source |
|---|---|---|---|---|
| Dialogue Manager | 4.2.0 | Nathan Hoad and contributors | MIT (`addons/dialogue_manager/LICENSE`) | https://github.com/nathanhoad/godot_dialogue_manager |
| GUT (Godot Unit Test) | 9.7.1 | Butch Wesley | MIT (`addons/gut/LICENSE.md`) | https://github.com/bitwes/Gut |
| Godot VRM importer | 2.0.1 (commit e15199f) | V-Sekai contributors | MIT (`addons/vrm/LICENSE`); sample models not included | https://github.com/V-Sekai/godot-vrm |
| Godot MToon shader | (same commit) | V-Sekai contributors, Masataka SUMI | MIT (`addons/Godot-MToon-Shader/LICENSE`) | https://github.com/V-Sekai/godot-vrm |
| Godot Engine | 4.7.2 | Godot contributors | MIT | https://godotengine.org (engine licence notice must ship with the game) |
