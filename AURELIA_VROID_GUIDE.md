# Making Aurelia in VRoid Studio: step by step

> For the owner. Written 2026-11-03 for Phase 2b. Reference art: `Game Images/white_hair_girl_character.jpeg`
> (and `pose_1/2/3.jpeg`). Keep that image open next to VRoid while you work.
> When you're done, tell me. I'll import her, give her the animations and staff, and make her the playable character.

---

## 0. Before you start (your PC)
- **Close Godot and most browser tabs.** VRoid Studio uses a lot of RAM, and your laptop has 8 GB.
- **Plug in the charger.**
- VRoid saves its own projects; **save often** (Ctrl+S).

## 1. Install VRoid Studio (free)
1. Download it from the official page: **vroid.com/en/studio** (or from **Steam**, where it's also free).
2. If the installer asks where to install, choose **D:** (for example `D:\Tools\VRoid Studio`). C: is nearly full.
   With Steam, use a Steam library folder on D:.
3. Open it and create a **New model → female base**.

---

## 2. Body
| Setting | Value |
|---|---|
| Height | Around **1.55–1.6 m** (VRoid shows the height). Slim, youthful build |
| Proportions | Natural anime proportions; don't exaggerate. The game camera is high above, so a slightly bigger head reads well |
| Skin | Fair, warm: **#F5DCCB** |

## 3. Face
| Part | What to set |
|---|---|
| **Eyes** | Large, gentle anime eyes. Iris colour **amber / golden brown, #C98A3A** |
| Eyebrows | Thin, soft, silver-grey |
| **Ears** | **Pointed elf ears.** In the face/ear settings, lengthen the ear tips and point them backwards and slightly up (see the art: the tips stick out of her hair) |
| Mouth / expression | Soft, friendly default; a slight smile |
| Blush | A little pink on the cheeks (she has it in all four pictures) |

## 4. Hair
| Part | What to set |
|---|---|
| Colour | **Silver-white, #DCDCE6**, with a faint lavender shadow tone |
| Length | **Long and straight**, to the middle of the back, flowing |
| Bangs | Soft, side-parted bangs framing the face; some strands in front of the ears |
| **Crown braid** | A braid across the top of the head, from one side to the other (like a headband) |
| **Side braid** | One thin braid at the side, hanging to the chest, with **small pale-blue/white beads** near the end (#8FD3FF) |

VRoid has braid presets in the hair editor. If a braid is hard to get right, a simple version is fine for now.

## 5. Outfit (from the reference art)
| Piece | Colour | Notes |
|---|---|---|
| **Dress** (underneath) | Cream **#E8E0C8** | Knee-length, visible at the front where the coat opens |
| **Sleeves** | Soft white **#F1EDE2** | Puffy, to the forearm |
| **Coat / tunic** | Dark green **#2F5A3A** | Knee-length, open at the front, high collar. **Gold trim #D4A849** along the edges (paint thin gold lines on the texture) |
| **Belts** | Brown leather **#5A3A24** | Two belts at the waist, plus a strap across the chest (paint on the coat if needed) |
| **Leggings** | Dark brown **#3A2A28** | |
| **Boots** | Brown leather **#5A3A24** | Ankle/calf height |
| **Gloves** | Brown leather, **fingerless** | If VRoid has no fingerless gloves, paint them on the hand texture, or skip |
| **Earrings** | Red teardrops **#C0392B** | If VRoid has none, skip; I'll add them in Godot |

### Leave these out; I add them in Godot
- **The plum hooded capelet and the long cape** (colour #4B2840 with gold trim). VRoid's clothing tools don't make good capes, so I'll model the cape in Blender and give it gentle physics sway.
- **The staff with its teal gem and lantern** (already built; she holds it automatically).
- **The satchel** on her left hip.

---

## 6. Check her
- Use VRoid's **photo/pose preview** to look at her from the front, the side and **from above**. The game camera is mostly above and behind her, so the hair and back of the coat matter most.
- Compare with `white_hair_girl_character.jpeg`. Silhouette and colours matter more than tiny details.

## 7. Export as VRM
1. Use **Export → Export as VRM**. Choose **VRM 1.0** if offered (VRM 0.0 also works).
2. **Information:** Title **Aurelia**; Author: your name.
3. **Permissions:** it's your own original model, so allow yourself everything (personal and commercial use).
4. **Reduce for games** (this keeps the game fast on your laptop):
   - **Polygon reduction:** reduce hair and clothing until the total is **under ~40,000 triangles** (VRoid shows the count).
   - **Material reduction / texture atlas:** reduce to **about 8 materials or fewer**, atlas size **2048 × 2048**.
   - **Keep the facial expressions** (blend shapes) and the hair/skirt sway (spring bones) turned **on**.
5. Save the file as:
   ```
   D:\Aethelgard\assets\models\characters\aurelia.vrm
   ```
   (create the `models\characters` folders if they don't exist).
6. Also **save the VRoid project** (`.vroid`) in `D:\Aethelgard\assets\models\characters\source\`, so you can edit her later.
   Both files are git-ignored, so they stay on your PC only, as you decided.

## 8. Then tell me. I will:
1. Import her and check her skeleton is a proper humanoid (needed for the animations).
2. Connect the **120+ CC0 animations** that already work on the stand-in (idle, walk, jog, dash, casting, hurt…).
3. Put the **staff** in her right hand and add the **cape**, **satchel** and **earrings**.
4. Check her with the anime shading in the character viewer, then make her the playable character.
5. Build the **style diorama**: a polished corner of Elderroot around her that locks the game's look.

---

### If something doesn't work
| Problem | What to do |
|---|---|
| VRoid is slow or freezes | Close other apps; lower VRoid's preview quality; save and restart it |
| Can't make elf ears | Make the ears as pointed as possible; I can sharpen them in Blender |
| Braids look messy | Use a simpler braid or skip the side braid; hair silhouette matters most |
| Can't find VRM 1.0 | Export VRM 0.0; the Godot importer supports both |
| File too big / too many polygons | Reduce hair polygons first; it's usually most of the count |
