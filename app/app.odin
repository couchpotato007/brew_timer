package main

import "base:runtime"
import clay "clay-odin"
import "core:c"
import "core:fmt"
import "core:math"
import "vendor:raylib"

windowWidth: i32 = 800
windowHeight: i32 = 400
run: bool

FONT_ID_BODY_16 :: 0

droplet_tex: raylib.Texture2D

any_hovered := false

Screen :: enum {
	Calculator,
	Recipe,
}

App_State :: struct {
	current_screen: Screen,
}

app_state := App_State {
	current_screen = .Calculator,
}


navigate_to :: proc(screen: Screen) {
	app_state.current_screen = screen
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

animationLerpValue: f32 = -1.0

createLayout :: proc(lerpValue: f32, frametime: f32) -> clay.ClayArray(clay.RenderCommand) {
	clay.BeginLayout()

	if clay.UI(clay.ID("OuterContainer"))(
	{
		layout = {
			sizing = {clay.SizingGrow(), clay.SizingGrow()},
			layoutDirection = .TopToBottom,
			padding = {bottom = sp_space(.XXL), top = sd(64), left = sp_space(.LG), right = sp_space(.LG)},
			childGap = sp_space(.MD),
			childAlignment = {x = clay.LayoutAlignmentX.Center},
		},
		backgroundColor = COLOR_BASE,
	},
	) {
		switch app_state.current_screen {
			case .Calculator:
				Calculator()
			case .Recipe:
				Render_Recipe()
		}

		Navigation()
	}
	return clay.EndLayout(frametime)
}


error_handler :: proc "c" (errorData: clay.ErrorData) {
	context = runtime.default_context()
	fmt.println(errorData.errorText)
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

		// init android keyboard
		android_install_text_input_hook()
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

	calc_derive()

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
