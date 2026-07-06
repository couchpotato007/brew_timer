package main

import "vendor:raylib"

ANDROID_UI_FUDGE :: f32(0.8)
DESKTOP_UI_FUDGE :: f32(1.0)

MIN_UI_SCALE :: f32(1.0)

ui_scale: f32 = 1.0
last_w, last_h: i32

update_ui_scale :: proc() {
	w := raylib.GetScreenWidth()
	h := raylib.GetScreenHeight()
	if w == last_w && h == last_h {
		return
	}
	last_w, last_h = w, h

	dpi := raylib.GetWindowScaleDPI()
	ui_scale = dpi.x

	when ODIN_PLATFORM_SUBTARGET == .Android {
		ui_scale *= ANDROID_UI_FUDGE
		ui_scale = max(ui_scale, MIN_UI_SCALE)
	} else {
		ui_scale *= DESKTOP_UI_FUDGE
	}
}

sp :: proc(base: f32) -> u16 {
	return u16(base * ui_scale + 0.5)
}

sd :: proc(base: i32) -> u16 {
	return u16(f32(base) * ui_scale + 0.5)
}
