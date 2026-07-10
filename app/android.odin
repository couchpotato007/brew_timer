package main

import "core:c"

when ODIN_PLATFORM_SUBTARGET == .Android {

	foreign import kb "keyboard.o"

	@(default_calling_convention = "c")
	foreign kb {
		android_install_text_input_hook :: proc() ---
		android_show_keyboard :: proc(show: c.bool) ---
		android_poll_text_char :: proc() -> c.int32_t ---
		android_poll_backspace :: proc() -> c.bool ---
		android_poll_enter :: proc() -> c.bool ---
	}

}
