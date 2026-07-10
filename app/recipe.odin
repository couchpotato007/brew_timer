package main

import clay "clay-odin"
import "core:fmt"
import "vendor:raylib"


Text_Input :: struct {
	buffer: [dynamic]rune,
	active: bool,
}

text_input := Text_Input{}

Render_Recipe :: proc() {
	if clay.UI_AutoId()({layout = {sizing = {clay.SizingGrow(), clay.SizingGrow()}}}) {
		if pressed() {
			when ODIN_PLATFORM_SUBTARGET == .Android {
				android_show_keyboard(true)
			}
		}
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
				if r == 0 {
					break
				}

				append(&text_input.buffer, r)
			}
		}

		text := fmt.tprintf("%v", text_input.buffer[:])
		clay.TextDynamic(text, {fontSize = font_size(.Label), textColor = COLOR_MAUVE})
	}
}
