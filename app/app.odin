package main

import "base:runtime"
import clay "clay-odin"
import "core:c"
import "core:fmt"
import "vendor:raylib"

windowWidth: i32 = 800
windowHeight: i32 = 400
run: bool

FONT_ID_BODY_16 :: 0

droplet_tex: raylib.Texture2D

COLOR_ROSEWATER :: clay.Color{245, 224, 220, 255}
COLOR_FLAMINGO :: clay.Color{242, 205, 205, 255}
COLOR_PINK :: clay.Color{245, 194, 231, 255}
COLOR_MAUVE :: clay.Color{203, 166, 247, 255}
COLOR_RED :: clay.Color{243, 139, 168, 255}
COLOR_MAROON :: clay.Color{235, 160, 172, 255}
COLOR_PEACH :: clay.Color{250, 179, 135, 255}
COLOR_YELLOW :: clay.Color{249, 226, 175, 255}
COLOR_GREEN :: clay.Color{166, 227, 161, 255}
COLOR_TEAL :: clay.Color{148, 226, 213, 255}
COLOR_SKY :: clay.Color{137, 220, 235, 255}
COLOR_SAPPHIRE :: clay.Color{116, 199, 236, 255}
COLOR_BLUE :: clay.Color{137, 180, 250, 255}
COLOR_LAVENDER :: clay.Color{180, 190, 254, 255}

COLOR_TEXT :: clay.Color{205, 214, 244, 255}
COLOR_TEXT_T50 :: clay.Color{205, 214, 244, 127}
COLOR_SUBTEXT1 :: clay.Color{186, 194, 222, 255}
COLOR_SUBTEXT0 :: clay.Color{166, 173, 200, 255}
COLOR_OVERLAY2 :: clay.Color{147, 153, 178, 255}
COLOR_OVERLAY1 :: clay.Color{127, 132, 156, 255}
COLOR_OVERLAY0 :: clay.Color{108, 112, 134, 255}
COLOR_SURFACE2 :: clay.Color{88, 91, 112, 255}
COLOR_SURFACE1 :: clay.Color{69, 71, 90, 255}
COLOR_SURFACE0 :: clay.Color{49, 50, 68, 255}

COLOR_BASE :: clay.Color{30, 30, 46, 255}
COLOR_MANTLE :: clay.Color{24, 24, 37, 255}
COLOR_CRUST :: clay.Color{17, 17, 27, 255}

any_hovered := false

Input_Mode :: enum {
	Coffee,
	Water,
}

Step_Info :: struct {
	time:  i32,
	water: i32,
}

App_State :: struct {
	ratio:            i32,
	coffee_fine_mode: bool,
	coffee_x10:       i32,
	water:            i32,
	input_mode:       Input_Mode,
	coffee_step:      i32, // 10 (=1.0g) or 5 (=0.5g)
	step_amount:      i32,
	bloom_ratio:      i32,
	accumulated:      bool,
}

state := App_State {
	ratio            = 16,
	coffee_fine_mode = false,
	coffee_x10       = 15 * 10,
	water            = 250,
	input_mode       = .Coffee,
	coffee_step      = 10,
	step_amount      = 5,
	bloom_ratio      = 3,
	accumulated      = true,
}

MAX_STEPS :: 5

Derived :: struct {
	water:        f32,
	coffee:       f32,
	coffee_label: string,
	water_label:  string,
	ratio_label:  string,
	steps:        [MAX_STEPS]Step_Info,
}

derived := Derived{}

derive :: proc() -> Derived {
	if state.step_amount > 5 {
		state.step_amount = 5
	}

	d: Derived

	switch state.input_mode {
		case .Coffee:
			d.coffee = f32(state.coffee_x10) / 10
			d.water = d.coffee * f32(state.ratio)
		case .Water:
			d.water = f32(state.water)
			d.coffee = d.water / f32(state.ratio)
	}

	if state.coffee_fine_mode {
		d.coffee_label = fmt.tprintf("%.1f g", d.coffee)
		state.coffee_step = 1
	} else {
		d.coffee_label = fmt.tprintf("%.0f g", d.coffee)
		state.coffee_step = 10
	}


	water_per_step := i32(d.water) / state.step_amount
	for i: i32 = 0; i < state.step_amount; i += 1 {
		d.steps[i] = Step_Info {
			water = water_per_step,
			time  = water_per_step * 1000,
		}
	}


	d.water_label = fmt.tprintf("%.0f g", d.water)
	d.ratio_label = fmt.tprintf("1:%d", state.ratio)

	return d
}

pressed :: proc() -> bool {
	if clay.Hovered() {
		any_hovered = true
		if raylib.IsMouseButtonPressed(.LEFT) {
			return true
		}
	}
	return false
}

Button :: proc(text: string, config: clay.ElementDeclaration, text_config: clay.TextElementConfig) -> bool {
	is_pressed := false
	if clay.UI_AutoId()(config) {
		is_pressed = pressed()
		clay.Text(text, text_config)
	}
	return is_pressed
}

Stepper :: proc(value: ^i32, step: i32, min: i32, max: i32, draw_label: proc()) {
	changed := false
	if clay.UI_AutoId()(
	{
		layout = {
			padding = clay.PaddingAll(sd(2)),
			layoutDirection = clay.LayoutDirection.TopToBottom,
			childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
		},
		cornerRadius = clay.CornerRadiusAll(f32(sd(8))),
	},
	) {
		button_layout_config := clay.LayoutConfig {
			padding = {bottom = sd(4), top = sd(4), left = sd(20), right = sd(20)},
		}
		text_config := clay.TextElementConfig {
			fontSize      = sp(58),
			textColor     = COLOR_TEXT,
			textAlignment = .Center,
		}
		if Button("+", {layout = button_layout_config, backgroundColor = COLOR_SURFACE0}, text_config) {
			value^ += step
		}
		draw_label()
		if Button("-", {layout = button_layout_config, backgroundColor = COLOR_SURFACE0}, text_config) {
			value^ -= step
		}
	}
}

animationLerpValue: f32 = -1.0

createLayout :: proc(lerpValue: f32, frametime: f32) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI(clay.ID("OuterContainer"))(
	{
		layout = {
			sizing = {clay.SizingGrow(), clay.SizingGrow()},
			layoutDirection = .TopToBottom,
			padding = clay.PaddingAll(sd(16)),
			childGap = sd(8),
			childAlignment = {x = clay.LayoutAlignmentX.Center},
		},
		backgroundColor = COLOR_BASE,
	},
	) {
		if clay.UI(clay.ID("UpperContainer"))(
		{
			layout = {
				sizing = {clay.SizingGrow(), clay.SizingGrow()},
				layoutDirection = clay.LayoutDirection.TopToBottom,
				padding = clay.PaddingAll(sd(8)),
				childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
			},
			cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
			backgroundColor = COLOR_SURFACE0,
		},
		) {
			if clay.UI_AutoId()(
			{
				layout = {
					childGap = sd(4),
					layoutDirection = clay.LayoutDirection.TopToBottom,
					childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
				},
			},
			) {
				if clay.UI_AutoId()(
				{
					layout = {
						layoutDirection = clay.LayoutDirection.LeftToRight,
						childGap = sd(6),
						padding = clay.PaddingAll(sd(6)),
					},
					cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
					backgroundColor = COLOR_BASE,
				},
				) {
					switch_layout := clay.LayoutConfig {
						padding = {left = sd(8), right = sd(8), top = sd(4), bottom = sd(4)},
					}
					if Button(
						"Water",
						{
							backgroundColor = state.input_mode == .Coffee ? COLOR_SURFACE0 : COLOR_BASE,
							layout = switch_layout,
							cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
						},
						{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
					) {
						state.input_mode = .Coffee
					}
					if Button(
						"Dose",
						{
							backgroundColor = state.input_mode == .Water ? COLOR_SURFACE0 : COLOR_BASE,
							layout = switch_layout,
							cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
						},
						{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
					) {
						state.input_mode = .Water
					}
				}
				if state.input_mode == .Coffee {
					clay.TextDynamic(derived.water_label, {fontSize = sp(34), textColor = COLOR_MAUVE})
				} else {
					clay.TextDynamic(derived.coffee_label, {fontSize = sp(34), textColor = COLOR_MAUVE})
				}

				if clay.UI_AutoId()(
				{layout = {layoutDirection = clay.LayoutDirection.LeftToRight, childGap = sd(4)}},
				) {
					for i: i32 = 0; i < state.step_amount; i += 1 {
						if clay.UI_AutoId()(
						{layout = {layoutDirection = .TopToBottom, childAlignment = {x = .Center}, childGap = sd(6)}},
						) {
							label: string
							if i == 1 {
								label = fmt.tprintf("%dst", i)
							} else if i == 2 {
								label = fmt.tprintf("%dnd", i)
							} else if i == 3 {
								label = fmt.tprintf("%drd", i)
							} else {
								label = fmt.tprintf("%dth", i)
							}
							clay.TextDynamic(fmt.tprint(label), {fontSize = sp(18), textColor = COLOR_TEXT})
							clay.TextDynamic(
								fmt.tprintf("%dg", derived.steps[i].water),
								{fontSize = sp(28), textColor = COLOR_RED},
							)
							clay.TextDynamic(
								fmt.tprintf("%d", derived.steps[i].time),
								{fontSize = sp(20), textColor = COLOR_TEXT},
							)
						}
					}
				}
				if clay.UI_AutoId()(
				{
					layout = {
						layoutDirection = clay.LayoutDirection.LeftToRight,
						childAlignment = {x = clay.LayoutAlignmentX.Center},
						childGap = sd(4),
					},
				},
				) {
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = clay.LayoutDirection.TopToBottom,
							childAlignment = {x = clay.LayoutAlignmentX.Center},
							childGap = sd(4),
						},
					},
					) {
						clay.TextStatic("Bloom ratio", {fontSize = sp(22), textColor = COLOR_TEXT_T50})
						if clay.UI_AutoId()(
						{
							layout = {
								layoutDirection = clay.LayoutDirection.LeftToRight,
								childGap = sd(6),
								padding = clay.PaddingAll(sd(6)),
							},
							cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
							backgroundColor = COLOR_BASE,
						},
						) {
							switch_layout := clay.LayoutConfig {
								padding = {left = sd(8), right = sd(8), top = sd(4), bottom = sd(4)},
							}
							if Button(
								"x3",
								{
									backgroundColor = state.bloom_ratio == 4 ? COLOR_SURFACE0 : COLOR_BASE,
									layout = switch_layout,
									cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
								},
								{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
							) {
								state.bloom_ratio = 4
							}
							if Button(
								"x4",
								{
									backgroundColor = state.bloom_ratio == 3 ? COLOR_SURFACE0 : COLOR_BASE,
									layout = switch_layout,
									cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
								},
								{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
							) {
								state.bloom_ratio = 3
							}
						}
					}
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = clay.LayoutDirection.TopToBottom,
							childAlignment = {x = clay.LayoutAlignmentX.Center},
							childGap = sd(4),
						},
					},
					) {
						clay.TextStatic("Pours", {fontSize = sp(22), textColor = COLOR_TEXT_T50})
						if clay.UI_AutoId()(
						{
							layout = {
								layoutDirection = clay.LayoutDirection.LeftToRight,
								childGap = sd(8),
								padding = clay.PaddingAll(sd(8)),
							},
							cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
							backgroundColor = COLOR_BASE,
						},
						) {
							is_pressed := pressed()
							if is_pressed {
								if state.step_amount < MAX_STEPS {
									state.step_amount += 1
								} else {
									state.step_amount = 2
								}
							}
							for i: i32 = 0; i < MAX_STEPS; i += 1 {
								switch_layout := clay.LayoutConfig {
									padding = clay.PaddingAll(sd(4)),
									sizing  = {clay.SizingGrow(), clay.SizingGrow()},
								}
								if clay.UI_AutoId()(
								{
									backgroundColor = i < state.step_amount ? COLOR_RED : COLOR_BASE,
									layout = switch_layout,
									cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
									image = {imageData = &droplet_tex},
								},
								) {
									if clay.UI_AutoId()(
									{
										layout = {
											sizing = {clay.SizingFixed(f32(sd(15))), clay.SizingFixed(f32(sd(15)))},
										},
										image = {imageData = &droplet_tex},
									},
									) {
									}

								}
							}
						}
					}
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = clay.LayoutDirection.TopToBottom,
							childAlignment = {x = clay.LayoutAlignmentX.Center},
							childGap = sd(4),
						},
					},
					) {
						clay.TextStatic("Accumulated", {fontSize = sp(22), textColor = COLOR_TEXT_T50})
						if clay.UI(clay.ID("AccumulatedToggle"))(
						{
							layout = {
								layoutDirection = clay.LayoutDirection.LeftToRight,
								// childGap = sd(6),
								padding = clay.PaddingAll(sd(8)),
								childAlignment = {x = state.accumulated ? .Right : .Left, y = .Center},
								sizing = {
									height = clay.SizingFixed(f32(sd(38))),
									width = clay.SizingFixed(f32(sd(60))),
								},
							},
							cornerRadius = clay.CornerRadiusAll(f32(sd(16))),
							backgroundColor = COLOR_BASE,
							border = {
								color = state.accumulated ? COLOR_MAUVE : COLOR_SURFACE0,
								width = {left = sd(1), right = sd(1), bottom = sd(1), top = sd(1)},
							},
							transition = {
								handler = clay.EaseOut,
								duration = 0.18,
								properties = {
									clay.TransitionProperty.BackgroundColor,
									clay.TransitionProperty.BorderColor,
								},
							},
						},
						) {
							is_pressed := pressed()
							if is_pressed {
								state.accumulated = !state.accumulated
							}
							padding := clay.Padding {
								left   = sd(4),
								right  = sd(4),
								top    = sd(4),
								bottom = sd(4),
							}
							if clay.UI(clay.ID("AccumulatedKnob"))(
							{
								layout = {
									padding = padding,
									sizing = {clay.SizingFixed(f32(sd(22))), clay.SizingFixed(f32(sd(22)))},
								},
								cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
								backgroundColor = state.accumulated ? COLOR_MAUVE : COLOR_SURFACE0,
								transition = {
									handler = clay.EaseOut,
									duration = 0.18,
									properties = {clay.TransitionProperty.BackgroundColor, clay.TransitionProperty.X},
								},
							},
							) {
							}
						}
					}
				}
			}
		}
		if clay.UI(clay.ID("BottomContainer"))(
		{
			layout = {
				sizing = {clay.SizingGrow(), clay.SizingGrow()},
				layoutDirection = clay.LayoutDirection.LeftToRight,
				childGap = sd(8),
			},
			cornerRadius = clay.CornerRadiusAll(f32(sd(8))),
		},
		) {
			inner_container_layout_config := clay.LayoutConfig {
				sizing = {height = clay.SizingGrow(), width = clay.SizingGrow()},
				childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
				layoutDirection = clay.LayoutDirection.TopToBottom,
				padding = clay.PaddingAll(sd(8)),
				childGap = sd(8),
			}

			if clay.UI(clay.ID("BottomInnerLeftContainer"))(
			{
				layout = inner_container_layout_config,
				cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
				backgroundColor = COLOR_SURFACE0,
			},
			) {
				clay.Text("1:X Ratio", {textColor = COLOR_TEXT_T50, fontSize = sp(22)})
				Stepper(
					&state.ratio,
					1,
					10,
					20,
					proc() {clay.TextDynamic(
							derived.ratio_label,
							{fontSize = sp(28), textColor = COLOR_MAUVE, textAlignment = .Center},
						)},
				)
			}
			if clay.UI(clay.ID("BottomInnerRightContainer"))(
			{
				layout = inner_container_layout_config,
				cornerRadius = clay.CornerRadiusAll(f32(sd(32))),
				backgroundColor = COLOR_SURFACE0,
			},
			) {

				if state.input_mode == .Coffee {
					clay.Text("Dose", {textColor = COLOR_TEXT_T50, fontSize = sp(22)})
					Stepper(
						&state.coffee_x10,
						state.coffee_step,
						10,
						20,
						proc() {clay.TextDynamic(
								derived.coffee_label,
								{fontSize = sp(28), textColor = COLOR_MAUVE, textAlignment = .Center},
							)},
					)

					button_config := clay.ElementDeclaration {
						layout = {padding = clay.PaddingAll(sd(8))},
						cornerRadius = clay.CornerRadiusAll(f32(sd(16))),
						border = {width = clay.BorderAll(sd(2)), color = COLOR_MAUVE},
					}


					if !state.coffee_fine_mode {
						if Button(
							" 0.5g on ",
							button_config,
							{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
						) {
							state.coffee_fine_mode = true
						}
					} else {
						if Button(
							" 0.5g off ",
							button_config,
							{fontSize = sp(20), textColor = COLOR_TEXT, textAlignment = .Center},
						) {
							state.coffee_fine_mode = false
						}
					}
				} else {
					clay.Text("Water", {textColor = COLOR_TEXT_T50, fontSize = sp(22)})
					Stepper(
						&state.water,
						1,
						10,
						500,
						proc() {clay.TextDynamic(
								derived.water_label,
								{fontSize = sp(28), textColor = COLOR_MAUVE, textAlignment = .Center},
							)},
					)
				}
			}
		}
	}
	return clay.EndLayout(frametime)
}

error_handler :: proc "c" (errorData: clay.ErrorData) {
	if (errorData.errorType == clay.ErrorType.DuplicateId) {
		// etc
	}
}

load_font :: proc(fontId: u16, fontSize: u16, path: cstring) {
	assign_at(
		&raylib_fonts,
		fontId,
		Raylib_Font{font = raylib.LoadFontEx(path, cast(i32)fontSize, nil, 0), fontId = cast(u16)fontId},
	)
	raylib.SetTextureFilter(raylib_fonts[fontId].font.texture, raylib.TextureFilter.TRILINEAR)
}

debugModeEnabled: bool = false


init :: proc() {
	run = true
	when ODIN_PLATFORM_SUBTARGET == .Android {
		raylib.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
		raylib.InitWindow(0, 0, "Pour Over Calc")
	}
	minMemorySize: c.size_t = cast(c.size_t)clay.MinMemorySize()
	memory := make([^]u8, minMemorySize)
	arena: clay.Arena = clay.CreateArenaWithCapacityAndMemory(minMemorySize, memory)
	clay.Initialize(
		arena,
		{cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()},
		{handler = error_handler},
	)

	when ODIN_PLATFORM_SUBTARGET != .Android {
		raylib.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE, .MSAA_4X_HINT})
		raylib.InitWindow(windowWidth, windowHeight, "Pour Over Calc")
	}
	clay.SetMeasureTextFunction(measure_text, nil)

	raylib.SetTargetFPS(raylib.GetMonitorRefreshRate(0))
	when ODIN_PLATFORM_SUBTARGET == .Android {
		load_font(FONT_ID_BODY_16, 56, "Iosevka-Regular.ttf")
		droplet_tex = raylib.LoadTexture("droplet.png")
	} else {
		load_font(FONT_ID_BODY_16, 56, "assets/Iosevka-Regular.ttf")
		droplet_tex = raylib.LoadTexture("assets/droplet.png")
	}
}

update :: proc() {
	defer free_all(context.temp_allocator)

	animationLerpValue += raylib.GetFrameTime()
	if animationLerpValue > 1 {
		animationLerpValue = animationLerpValue - 2
	}
	windowWidth = raylib.GetScreenWidth()
	windowHeight = raylib.GetScreenHeight()
	if (raylib.IsKeyPressed(.D)) {
		debugModeEnabled = !debugModeEnabled
		clay.SetDebugModeEnabled(debugModeEnabled)
	}
	clay.SetPointerState(
		transmute(clay.Vector2)raylib.GetMousePosition(),
		raylib.IsMouseButtonDown(raylib.MouseButton.LEFT),
	)

	clay.UpdateScrollContainers(false, transmute(clay.Vector2)raylib.GetMouseWheelMoveV(), raylib.GetFrameTime())
	clay.SetLayoutDimensions({cast(f32)raylib.GetScreenWidth(), cast(f32)raylib.GetScreenHeight()})

	update_ui_scale()

	derived = derive()

	any_hovered = false

	renderCommands := createLayout(
		animationLerpValue < 0 ? (animationLerpValue + 1) : (1 - animationLerpValue),
		raylib.GetFrameTime(),
	)

	raylib.SetMouseCursor(any_hovered ? raylib.MouseCursor.POINTING_HAND : raylib.MouseCursor.DEFAULT)
	raylib.BeginDrawing()
	clay_raylib_render(&renderCommands)
	raylib.EndDrawing()
}

when ODIN_PLATFORM_SUBTARGET == .Android {
	@(export)
	Game_Main :: proc "c" (argc: c.int, argv: [^]cstring) -> c.int {
		context = runtime.default_context()
		init()
		for !raylib.WindowShouldClose() {
			update()
		}
		return 0
	}
} else {
	main :: proc() {
		init()
		for !raylib.WindowShouldClose() {
			update()
		}
	}
}
