package main

import "base:runtime"
import clay "clay-odin"
import "core:c"
import "core:fmt"
import "core:math"
import "vendor:raylib"

MAX_STEPS :: 5

Input_Mode :: enum {
	Coffee,
	Water,
}

Step_Info :: struct {
	accumulated: i32,
	water:       i32,
}

Calc_State :: struct {
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

calc_state := Calc_State {
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

Calc_Derived :: struct {
	water:        f32,
	coffee:       f32,
	coffee_label: string,
	water_label:  string,
	ratio_label:  string,
	steps:        [MAX_STEPS]Step_Info,
}

calc_derived := Calc_Derived{}

calc_derive :: proc() {
	if calc_state.step_amount > 5 {
		calc_state.step_amount = 5
	}


	d: Calc_Derived

	switch calc_state.input_mode {
		case .Coffee:
			if calc_state.coffee_fine_mode {
				d.coffee = f32(calc_state.coffee_x10) / 10
			} else {
				d.coffee = math.round(f32(calc_state.coffee_x10) / 10)
			}
			d.water = d.coffee * f32(calc_state.ratio)
		case .Water:
			d.water = f32(calc_state.water)
			d.coffee = d.water / f32(calc_state.ratio)
	}

	if calc_state.coffee_fine_mode {
		d.coffee_label = fmt.tprintf("%.1f g", d.coffee)
		calc_state.coffee_step = 1
	} else {
		d.coffee_label = fmt.tprintf("%.0f g", d.coffee)
		calc_state.coffee_step = 10
	}

	if calc_state.input_mode == .Water {
		d.coffee_label = fmt.tprintf("%.1f g", d.coffee)
	}


	water_per_step := i32(d.water) / calc_state.step_amount
	for i: i32 = 0; i < calc_state.step_amount; i += 1 {
		accumulated := water_per_step
		if i > 0 {
			accumulated += d.steps[i - 1].accumulated
		}
		d.steps[i] = Step_Info {
			water       = water_per_step,
			accumulated = accumulated,
		}
	}

	d.water_label = fmt.tprintf("%.0f g", d.water)
	d.ratio_label = fmt.tprintf("1:%d", calc_state.ratio)

	calc_derived = d

}


Calculator :: proc() {
	if clay.UI(clay.ID("UpperContainer"))(
	{
		layout = {
			sizing = {clay.SizingGrow(), clay.SizingGrow()},
			layoutDirection = clay.LayoutDirection.TopToBottom,
			padding = clay.PaddingAll(sp_space(.MD)),
			childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
		},
		cornerRadius = clay.CornerRadiusAll(radius(.LG)),
		backgroundColor = COLOR_SURFACE0,
	},
	) {
		if clay.UI_AutoId()(
		{
			layout = {
				childGap = sp_space(.XS),
				layoutDirection = clay.LayoutDirection.TopToBottom,
				childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
			},
		},
		) {
			if clay.UI_AutoId()(
			{
				layout = {
					layoutDirection = clay.LayoutDirection.LeftToRight,
					childGap = sp_space(.SM),
					padding = clay.PaddingAll(sp_space(.SM)),
				},
				cornerRadius = clay.CornerRadiusAll(radius(.LG)),
				backgroundColor = COLOR_BASE,
			},
			) {
				switch_layout := clay.LayoutConfig {
					padding = {
						left = sp_space(.MD),
						right = sp_space(.MD),
						top = sp_space(.XS),
						bottom = sp_space(.XS),
					},
				}
				if Button(
					"Water",
					{
						backgroundColor = calc_state.input_mode == .Coffee ? COLOR_SURFACE0 : COLOR_BASE,
						layout = switch_layout,
						cornerRadius = clay.CornerRadiusAll(radius(.LG)),
					},
					{fontSize = font_size(.Label), textColor = COLOR_TEXT, textAlignment = .Center},
				) {
					calc_state.input_mode = .Coffee
				}
				if Button(
					"Dose",
					{
						backgroundColor = calc_state.input_mode == .Water ? COLOR_SURFACE0 : COLOR_BASE,
						layout = switch_layout,
						cornerRadius = clay.CornerRadiusAll(radius(.LG)),
					},
					{fontSize = font_size(.Label), textColor = COLOR_TEXT, textAlignment = .Center},
				) {
					calc_state.input_mode = .Water
				}
			}
			if calc_state.input_mode == .Coffee {
				clay.TextDynamic(calc_derived.water_label, {fontSize = font_size(.Display), textColor = COLOR_MAUVE})
			} else {
				clay.TextDynamic(calc_derived.coffee_label, {fontSize = font_size(.Display), textColor = COLOR_MAUVE})
			}

			if clay.UI_AutoId()(
			{
				layout = {layoutDirection = clay.LayoutDirection.LeftToRight, childGap = sp_space(.XXL)},
				transition = {
					handler = clay.EaseOut,
					duration = 0.18,
					properties = {clay.TransitionProperty.X, clay.TransitionProperty.Width},
				},
			},
			) {
				for i: i32 = 0; i < calc_state.step_amount; i += 1 {
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = .TopToBottom,
							sizing = {width = clay.SizingFixed(radius(.LG))},
							childAlignment = {x = .Center},
							childGap = sp_space(.SM),
						},
					},
					) {
						label: string
						if i == 0 {
							label = fmt.tprintf("%dst", i + 1)
						} else if i == 1 {
							label = fmt.tprintf("%dnd", i + 1)
						} else if i == 2 {
							label = fmt.tprintf("%drd", i + 1)
						} else {
							label = fmt.tprintf("%dth", i + 1)
						}
						clay.TextDynamic(fmt.tprint(label), {fontSize = font_size(.Body), textColor = COLOR_TEXT})
						clay.TextDynamic(
							fmt.tprintf(
								"%dg",
								calc_state.accumulated ? calc_derived.steps[i].accumulated : calc_derived.steps[i].water,
							),
							{fontSize = font_size(.Value), textColor = COLOR_RED},
						)
						clay.TextDynamic(
							fmt.tprintf(
								"%d",
								calc_state.accumulated ? calc_derived.steps[i].water : calc_derived.steps[i].accumulated,
							),
							{fontSize = font_size(.Label), textColor = COLOR_TEXT},
						)
					}
				}
			}
			if clay.UI_AutoId()(
			{
				layout = {
					layoutDirection = clay.LayoutDirection.LeftToRight,
					childAlignment = {x = clay.LayoutAlignmentX.Center},
					sizing = {height = clay.SizingFixed(f32(sd(38)))},
					childGap = sp_space(.XS),
				},
			},
			) {
				if clay.UI_AutoId()(
				{
					layout = {
						layoutDirection = clay.LayoutDirection.TopToBottom,
						childAlignment = {x = clay.LayoutAlignmentX.Center},
						childGap = sp_space(.XS),
					},
				},
				) {
					clay.TextStatic("Bloom ratio", {fontSize = font_size(.Label), textColor = COLOR_TEXT_T50})
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = clay.LayoutDirection.LeftToRight,
							childGap = sp_space(.MD),
							padding = clay.PaddingAll(sp_space(.SM)),
						},
						cornerRadius = clay.CornerRadiusAll(radius(.LG)),
						backgroundColor = COLOR_BASE,
					},
					) {
						switch_layout := clay.LayoutConfig {
							padding = {
								left = sp_space(.MD),
								right = sp_space(.MD),
								top = sp_space(.XS),
								bottom = sp_space(.XS),
							},
						}
						if Button(
							"x3",
							{
								backgroundColor = calc_state.bloom_ratio == 3 ? COLOR_SURFACE0 : COLOR_BASE,
								layout = switch_layout,
								cornerRadius = clay.CornerRadiusAll(radius(.LG)),
							},
							{fontSize = font_size(.Label), textColor = COLOR_TEXT, textAlignment = .Center},
						) {
							calc_state.bloom_ratio = 3
						}
						if Button(
							"x4",
							{
								backgroundColor = calc_state.bloom_ratio == 4 ? COLOR_SURFACE0 : COLOR_BASE,
								layout = switch_layout,
								cornerRadius = clay.CornerRadiusAll(radius(.LG)),
							},
							{fontSize = font_size(.Label), textColor = COLOR_TEXT, textAlignment = .Center},
						) {
							calc_state.bloom_ratio = 4
						}
					}
				}
				if clay.UI_AutoId()(
				{
					layout = {
						layoutDirection = clay.LayoutDirection.TopToBottom,
						childAlignment = {x = clay.LayoutAlignmentX.Center},
						childGap = sp_space(.XS),
					},
				},
				) {
					clay.TextStatic("Pours", {fontSize = font_size(.Label), textColor = COLOR_TEXT_T50})
					if clay.UI_AutoId()(
					{
						layout = {
							layoutDirection = clay.LayoutDirection.LeftToRight,
							childGap = sp_space(.MD),
							padding = clay.PaddingAll(sp_space(.MD)),
						},
						cornerRadius = clay.CornerRadiusAll(radius(.LG)),
						backgroundColor = COLOR_BASE,
					},
					) {
						is_pressed := pressed()
						if is_pressed {
							if calc_state.step_amount < MAX_STEPS {
								calc_state.step_amount += 1
							} else {
								calc_state.step_amount = 2
							}
						}
						for i: i32 = 0; i < MAX_STEPS; i += 1 {
							switch_layout := clay.LayoutConfig {
								padding = clay.PaddingAll(sp_space(.XS)),
								sizing  = {clay.SizingGrow(), clay.SizingGrow()},
							}
							if clay.UI_AutoId()(
							{
								backgroundColor = i < calc_state.step_amount ? COLOR_RED : COLOR_BASE,
								layout = switch_layout,
								cornerRadius = clay.CornerRadiusAll(radius(.LG)),
								image = {imageData = &droplet_tex},
							},
							) {
								if clay.UI_AutoId()(
								{
									layout = {sizing = {clay.SizingFixed(f32(sd(15))), clay.SizingFixed(f32(sd(15)))}},
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
						childGap = sp_space(.XS),
					},
				},
				) {
					clay.TextStatic("Accumulated", {fontSize = font_size(.Label), textColor = COLOR_TEXT_T50})
					Toggle(&calc_state.accumulated, COLOR_MAUVE, 38)
				}
			}
		}
	}
	if clay.UI(clay.ID("BottomContainer"))(
	{
		layout = {
			sizing = {clay.SizingGrow(), clay.SizingGrow()},
			layoutDirection = clay.LayoutDirection.LeftToRight,
			childGap = sp_space(.MD),
		},
		cornerRadius = clay.CornerRadiusAll(radius(.SM)),
	},
	) {
		inner_container_layout_config := clay.LayoutConfig {
			sizing = {height = clay.SizingGrow(), width = clay.SizingGrow()},
			childAlignment = {x = clay.LayoutAlignmentX.Center, y = clay.LayoutAlignmentY.Center},
			layoutDirection = clay.LayoutDirection.TopToBottom,
			padding = clay.PaddingAll(sp_space(.MD)),
			childGap = sp_space(.MD),
		}

		if clay.UI(clay.ID("BottomInnerLeftContainer"))(
		{
			layout = inner_container_layout_config,
			cornerRadius = clay.CornerRadiusAll(radius(.LG)),
			backgroundColor = COLOR_SURFACE0,
		},
		) {
			clay.Text("1:X Ratio", {textColor = COLOR_TEXT_T50, fontSize = font_size(.Label)})
			Stepper(
				&calc_state.ratio,
				1,
				10,
				20,
				proc() {clay.TextDynamic(
						calc_derived.ratio_label,
						{fontSize = font_size(.Value), textColor = COLOR_MAUVE, textAlignment = .Center},
					)},
			)
		}
		if clay.UI(clay.ID("BottomInnerRightContainer"))(
		{
			layout = inner_container_layout_config,
			cornerRadius = clay.CornerRadiusAll(radius(.LG)),
			backgroundColor = COLOR_SURFACE0,
		},
		) {

			if calc_state.input_mode == .Coffee {
				clay.Text("Dose", {textColor = COLOR_TEXT_T50, fontSize = font_size(.Label)})
				Stepper(
					&calc_state.coffee_x10,
					calc_state.coffee_step,
					60,
					500,
					proc() {clay.TextDynamic(
							calc_derived.coffee_label,
							{fontSize = font_size(.Value), textColor = COLOR_MAUVE, textAlignment = .Center},
						)},
				)

				button_config := clay.ElementDeclaration {
					layout = {padding = clay.PaddingAll(sp_space(.MD))},
					cornerRadius = clay.CornerRadiusAll(radius(.MD)),
					border = {width = clay.BorderAll(sp_space(.XXS)), color = COLOR_MAUVE},
				}


				if !calc_state.coffee_fine_mode {
					if Button(
						" 0.5g on ",
						button_config,
						{fontSize = font_size(.Body), textColor = COLOR_TEXT, textAlignment = .Center},
					) {
						calc_state.coffee_fine_mode = true
					}
				} else {
					if Button(
						" 0.5g off ",
						button_config,
						{fontSize = font_size(.Body), textColor = COLOR_TEXT, textAlignment = .Center},
					) {
						calc_state.coffee_fine_mode = false
					}
				}
			} else {
				clay.Text("Water", {textColor = COLOR_TEXT_T50, fontSize = font_size(.Label)})
				Stepper(
					&calc_state.water,
					5,
					10,
					800,
					proc() {clay.TextDynamic(
							calc_derived.water_label,
							{fontSize = font_size(.Value), textColor = COLOR_MAUVE, textAlignment = .Center},
						)},
				)
			}
		}
	}
}
