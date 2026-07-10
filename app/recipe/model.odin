package recipe

Step_Kind :: enum {
	Custom,
	Add_Coffee,
	Add_Ice,
	Pour_Water,
}

Step :: struct {
	kind:     Step_Kind,
	name:     string,
	duration: i32,
	note:     string,
}

Grind_Size :: enum {
	Fine,
	Medium_Fine,
	Medium,
	Medium_Coarse,
	Coarse,
}

Recipe :: struct {
	name:       string,
	note:       string,
	dose:       f32,
	water:      i32,
	grind_size: Grind_Size,
	heat:       i32,
}
