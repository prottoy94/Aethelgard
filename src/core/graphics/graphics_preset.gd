class_name GraphicsPreset
extends Resource
## One graphics quality level (Low / Medium / High). Settings picks the active preset;
## levels apply it to their viewport, environment, sun and grass.
## High targets the owner's RTX 3050 at 60 FPS; Low is for integrated graphics (BUILD_PLAN.md §3).

@export var id: StringName
@export var display_name: String
## Fraction of the window resolution the 3D scene renders at (UI stays sharp).
@export_range(0.5, 1.0, 0.05) var render_scale: float = 1.0
@export var scaling_mode: Viewport.Scaling3DMode = Viewport.SCALING_3D_MODE_BILINEAR
@export var msaa: Viewport.MSAA = Viewport.MSAA_2X
@export var shadows: bool = true
@export var shadow_distance: float = 60.0
@export var ssao: bool = true
@export var glow: bool = true
@export var fog: bool = true
@export_range(0.0, 1.0, 0.05) var grass_density: float = 1.0


func apply_to_viewport(viewport: Viewport) -> void:
	viewport.scaling_3d_mode = scaling_mode
	viewport.scaling_3d_scale = render_scale
	viewport.msaa_3d = msaa


func apply_to_environment(environment: Environment) -> void:
	environment.ssao_enabled = ssao
	environment.glow_enabled = glow
	environment.fog_enabled = fog


func apply_to_sun(sun: DirectionalLight3D) -> void:
	sun.shadow_enabled = shadows
	sun.directional_shadow_max_distance = shadow_distance


func visible_grass(total: int) -> int:
	return roundi(total * grass_density)
