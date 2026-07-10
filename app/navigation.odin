package main

import clay "clay-odin"

Nav_Item :: struct {
	screen: Screen,
	label:  string,
}

nav_items := [?]Nav_Item{{.Recipe, "Recipe"}, {.Calculator, "Calculator"}}


Navigation :: proc() {
	if clay.UI_AutoId()(
	{
		layout = {sizing = {width = clay.SizingGrow(), height = clay.SizingFixed(f32(sd(80)))}},
		backgroundColor = COLOR_SURFACE0,
		cornerRadius = clay.CornerRadiusAll(radius(.MD)),
	},
	) {
		for item, i in nav_items {
			is_active := app_state.current_screen == item.screen

			if clay.UI_AutoId()(
			{
				layout = {
					sizing = {width = clay.SizingGrow(), height = clay.SizingGrow()},
					childAlignment = {x = .Center, y = .Center},
					childGap = sp_space(.XXS),
				},
				cornerRadius = clay.CornerRadiusAll(radius(.MD)),
				backgroundColor = is_active ? COLOR_SURFACE1 : COLOR_SURFACE0,
			},
			) {
				if pressed() {
					app_state.current_screen = item.screen
				}

				clay.Text(
					item.label,
					{
						fontSize = font_size(.Caption),
						textColor = is_active ? COLOR_MAUVE : COLOR_TEXT_T50,
						textAlignment = .Center,
					},
				)

			}
		}
	}
}
