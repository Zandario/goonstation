/datum/fluid_group/airborne
	base_evaporation_time = 30 SECONDS
	bonus_evaporation_time = 30 SECONDS
	drains_floor = FALSE
	group_type = /obj/fluid/airborne
	// max_alpha = 200
	required_to_spread = 5

/datum/fluid_group/airborne/update_required_to_spread()
	// So many magicks
	var/smoke_spread_val = 0.25 + src.reagents.get_smoke_spread_mod()
	var/magic_contained_val = (src.contained_volume ** 0.8) / 40
	required_to_spread = min(15, max(smoke_spread_val, magic_contained_val) + 0.65) //wowowow magic numbers
