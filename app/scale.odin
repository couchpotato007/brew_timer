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

Space :: enum {
	XXS,
	XS,
	SM,
	MD,
	LG,
	XL,
	XXL,
}
space_px := [Space]i32 {
	.XXS = 2,
	.XS  = 4,
	.SM  = 6,
	.MD  = 8,
	.LG  = 16,
	.XL  = 24,
	.XXL = 32,
}
sp_space :: proc(s: Space) -> u16 {return sd(space_px[s])}

Radius :: enum {
	SM,
	MD,
	LG,
	Full,
}
radius_px := [Radius]i32 {
	.SM   = 8,
	.MD   = 16,
	.LG   = 24,
	.Full = 999,
}
radius :: proc(r: Radius) -> f32 {return f32(sd(radius_px[r]))}

Font :: enum {
	Caption,
	Body,
	Label,
	Value,
	Display,
	Huge,
}
font_px := [Font]f32 {
	.Caption = 16,
	.Body    = 18,
	.Label   = 22,
	.Value   = 28,
	.Display = 34,
	.Huge    = 58,
}
font_size :: proc(f: Font) -> u16 {return sp(font_px[f])}


sp :: proc(base: f32) -> u16 {
	return u16(base * ui_scale + 0.5)
}

sd :: proc(base: i32) -> u16 {
	return u16(f32(base) * ui_scale + 0.5)
}
