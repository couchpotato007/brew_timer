package main

import "base:intrinsics"
import clay "clay-odin"


Button :: proc(text: string, config: clay.ElementDeclaration, text_config: clay.TextElementConfig) -> bool {
	is_pressed := false
	if clay.UI_AutoId()(config) {
		is_pressed = pressed()
		clay.Text(text, text_config)
	}
	return is_pressed
}

Stepper :: proc(value: ^$T, step: i32, min: i32, max: i32, draw_label: proc()) where intrinsics.type_is_numeric(T) {
	changed := false
	if clay.UI_AutoId()(
	{
		layout = {
			padding = clay.PaddingAll(sp_space(.XXS)),
			layoutDirection = clay.LayoutDirection.TopToBottom,
			childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
		},
		cornerRadius = clay.CornerRadiusAll(radius(.SM)),
	},
	) {
		button_layout_config := clay.LayoutConfig {
			padding = {left = sp_space(.XL), right = sp_space(.XL), top = sp_space(.XS), bottom = sp_space(.XS)},
		}
		text_config := clay.TextElementConfig {
			fontSize      = font_size(.Huge),
			textColor     = COLOR_TEXT,
			textAlignment = .Center,
		}
		if Button("+", {layout = button_layout_config, backgroundColor = COLOR_SURFACE0}, text_config) {
			new_val := i32(value^) + step
			value^ = T(clamp(new_val, min, max))
		}
		draw_label()
		if Button("-", {layout = button_layout_config, backgroundColor = COLOR_SURFACE0}, text_config) {
			new_val := i32(value^) - step
			value^ = T(clamp(new_val, min, max))
		}
	}
}


Toggle :: proc(checked: ^bool, color: clay.Color, size: i32) {
	if clay.UI_AutoId()(
	{
		layout = {
			layoutDirection = clay.LayoutDirection.LeftToRight,
			padding = clay.PaddingAll(sp_space(.MD)),
			childAlignment = {x = checked^ ? .Right : .Left, y = .Center},
			sizing = {height = clay.SizingFixed(f32(sd(size))), width = clay.SizingFixed(f32(sd(size)) * 1.7)},
		},
		cornerRadius = clay.CornerRadiusAll(radius(.MD)),
		backgroundColor = COLOR_BASE,
		border = {
			color = checked^ ? color : COLOR_SURFACE0,
			width = {left = sd(1), right = sd(1), bottom = sd(1), top = sd(1)},
		},
		transition = {
			handler = clay.EaseOut,
			duration = 0.18,
			properties = {clay.TransitionProperty.BackgroundColor, clay.TransitionProperty.BorderColor},
		},
	},
	) {
		is_pressed := pressed()
		if is_pressed {
			checked^ = !checked^
		}
		padding := clay.Padding {
			left   = sp_space(.XS),
			right  = sp_space(.XS),
			top    = sp_space(.XS),
			bottom = sp_space(.XS),
		}
		if clay.UI_AutoId()(
		{
			layout = {padding = padding, sizing = {clay.SizingFixed(f32(sd(22))), clay.SizingFixed(f32(sd(22)))}},
			cornerRadius = clay.CornerRadiusAll(radius(.LG)),
			backgroundColor = checked^ ? color : COLOR_SURFACE0,
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

SwapCheckbox :: proc(checked: ^bool, color: clay.Color, draw_label: proc()) {
	is_pressed := pressed()
	if is_pressed {
		checked^ = !checked^
	}
	if clay.UI_AutoId()(
	{
		layout = {padding = clay.PaddingAll(sd(8))},
		cornerRadius = clay.CornerRadiusAll(f32(sd(16))),
		border = {width = clay.BorderAll(sd(2)), color = COLOR_MAUVE},
		transition = {handler = clay.EaseOut, duration = 0.18, properties = {clay.TransitionProperty.BackgroundColor}},
	},
	) {
		draw_label()
	}
}
