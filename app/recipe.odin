package main

import clay "clay-odin"
import "core:fmt"
import "core:strings"
import "core:unicode/utf8"
import "vendor:raylib"


Text_Input :: struct {
	buffer:     [dynamic]rune,
	cursor_pos: i32,
	active:     bool,
}

text_input := Text_Input{}

insert_at_cursor :: proc(ti: ^Text_Input, r: rune) {
	inject_at(&ti.buffer, ti.cursor_pos, r)
	ti.cursor_pos += 1
}

backspace_at_cursor :: proc(ti: ^Text_Input) {
	if ti.cursor_pos <= 0 do return
	ordered_remove(&ti.buffer, ti.cursor_pos - 1)
	ti.cursor_pos -= 1
}

delete_at_cursor :: proc(ti: ^Text_Input) {
	if ti.cursor_pos >= i32(len(ti.buffer)) do return
	ordered_remove(&ti.buffer, ti.cursor_pos)
}

move_cursor :: proc(ti: ^Text_Input, delta: i32) {
	ti.cursor_pos = clamp(ti.cursor_pos + delta, 0, i32(len(ti.buffer)))
}


Render_Recipe :: proc() {
	if clay.UI_AutoId()({layout = {sizing = {clay.SizingGrow(), clay.SizingGrow()}}}) {
		if pressed() {
			text_input.active = false
			when ODIN_PLATFORM_SUBTARGET == .Android {
				android_show_keyboard(false)
			}
		}
		if clay.UI_AutoId()(
		{
			backgroundColor = COLOR_SURFACE0,
			layout = {sizing = {width = clay.SizingFixed(f32(sp(200))), height = clay.SizingFixed(f32(sp(100)))}},
		},
		) {
			if pressed() {
				when ODIN_PLATFORM_SUBTARGET == .Android {
					if !text_input.active do android_show_keyboard(true)
				}
				text_input.active = true
			}
			if clay.UI_AutoId()({clip = {horizontal = true, childOffset = clay.GetScrollOffset()}}) {
				if text_input.active {

					when ODIN_PLATFORM_SUBTARGET == .Android {
						for {
							cp := android_poll_text_char()
							if cp == 0 do break
							append(&text_input.buffer, rune(cp))
						}
						if android_poll_backspace() && len(text_input.buffer) > 0 {
							pop(&text_input.buffer)
						}
						if android_poll_enter() {
							android_show_keyboard(false)
						}
					} else {
						for {
							r := raylib.GetCharPressed()
							if r == 0 do break
							insert_at_cursor(&text_input, r)
						}
						if raylib.IsKeyPressed(.ENTER) do insert_at_cursor(&text_input, rune('\n'))
						if raylib.IsKeyPressed(.BACKSPACE) do backspace_at_cursor(&text_input)
						if raylib.IsKeyPressed(.DELETE) do delete_at_cursor(&text_input)
						if raylib.IsKeyPressed(.LEFT) do move_cursor(&text_input, -1)
						if raylib.IsKeyPressed(.RIGHT) do move_cursor(&text_input, 1)
					}
				}


				if clay.UI_AutoId()({layout = {layoutDirection = .LeftToRight, childAlignment = {y = .Center}}}) {
					before := utf8.runes_to_string(text_input.buffer[:text_input.cursor_pos], context.temp_allocator)
					after := utf8.runes_to_string(text_input.buffer[text_input.cursor_pos:], context.temp_allocator)

					text_width :=
						raylib.MeasureTextEx(raylib_fonts[FONT_ID_BODY_16].font, strings.clone_to_cstring(before, context.temp_allocator), f32(font_size(.Label)), 0).x
					if clay.UI_AutoId()({layout = {sizing = {width = clay.SizingFixed(text_width)}}}) {
						clay.TextDynamic(
							before,
							{fontSize = font_size(.Label), textColor = COLOR_MAUVE, wrapMode = .None},
						)
					}

					blink := i32(raylib.GetTime() * 2) % 2 == 0
					if text_input.active && blink {
						if clay.UI_AutoId()(
						{
							layout = {
								sizing = {
									width = clay.SizingFixed(2),
									height = clay.SizingFixed(f32(font_px[Font.Label])),
								},
							},
							backgroundColor = COLOR_MAUVE,
						},
						) {}
					} else {
						if clay.UI_AutoId()({layout = {sizing = {width = clay.SizingFixed(2)}}}) {}
					}

					clay.TextDynamic(after, {fontSize = font_size(.Label), textColor = COLOR_MAUVE, wrapMode = .None})
				}
			}
		}
	}
}
