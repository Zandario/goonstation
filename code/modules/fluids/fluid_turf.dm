//fluid as a space tile
//on turfnotify, will start processing fluid creation

#define SPAWN_DECOR 1
#define SPAWN_PLANTS 2
#define SPAWN_FISH 4
#define SPAWN_LOOT 8
#define SPAWN_PLANTSMANTA 16
#define SPAWN_TRILOBITE 32
#define SPAWN_HALLU 64
#define SPAWN_HOSTILE 128
#define SPAWN_ACID_DOODADS 256


/turf/proc/make_light() //dummyproc so we can inherit
	return FALSE

/proc/fluid_turf_setup(first_time=FALSE)
	if(QDELETED(ocean_fluid_obj))
		ocean_fluid_obj = new
	var/datum/fluid_group/FG = new
	FG.add(ocean_fluid_obj)
	ocean_fluid_obj.group = FG
	ocean_fluid_obj.my_depth_level = 4 // maybe a good idea to change to 5 so it's possible to distinguish ocean at some point
	FG.reagents.add_reagent(ocean_reagent_id, INFINITY)


/turf/space/fluid
	name = "ocean floor"
	icon = 'icons/turf/outdoors.dmi'
	icon_state = "sand_other"
	color = OCEAN_COLOR
	pathable = 1
	mat_changename = 0
	mat_changedesc = 0
	fullbright = 0
	luminosity = 1
	intact = 0 //allow wire laying
	throw_unlimited = 0
	//todo fix : cannot flip.
	//todo : TOUCH reagent func

	oxygen = MOLES_O2STANDARD * 0.5
	nitrogen = MOLES_N2STANDARD * 0.5
	temperature = OCEAN_TEMP
	thermal_conductivity = OPEN_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 700000

	special_volume_override = 0.62

	turf_flags = FLUID_MOVE

	var/datum/light/point/light = 0
	var/light_r = 0.16
	var/light_g = 0.6
	var/light_b = 0.8

	var/light_brightness = 0.8
	var/light_height = 3

	var/spawningFlags = SPAWN_DECOR | SPAWN_PLANTS | SPAWN_FISH
	var/randomIcon = TRUE

	var/generateLight = TRUE //do we sometimes generate a special light?

	var/captured = FALSE //Thermal vent collector on my tile? (messy i know, but faster lookups later)

	var/allow_hole = TRUE

	var/linked_hole = null


/turf/space/fluid/New()
	..()

	if(global.dont_init_space)
		return
	if(randomIcon)
		switch(rand(1, 3))
			if(1)
				icon_state = "sand_other_texture"
				src.set_dir(pick(global.alldirs))
			if(2)
				icon_state = "sand_other_texture2"
				src.set_dir(pick(global.alldirs))
			if(3)
				icon_state = "sand_other_texture3"
				src.set_dir(pick(global.cardinal))

	if(spawningFlags && current_state <= GAME_STATE_WORLD_INIT)
		//worldgenCandidates[src] = 1 //Adding self to possible worldgen turfs
		// idk about the above. walls still use [src]=1 ...
		// the bottom is much faster in my testing and works just as well
		// maybe should be converted to this everywhere?
		if(src.z == Z_LEVEL_STATION || src.z == Z_LEVEL_MINING)
			worldgenCandidates += src //Adding self to possible worldgen turfs

	if(current_state > GAME_STATE_WORLD_INIT)
		for(var/dir in cardinal)
			var/turf/T = get_step(src, dir)
			if(istype(T) && T.ocean_canpass() && !istype(T, /turf/space))
				src.tilenotify(T)
				break

	//globals defined in fluid_spawner
	#ifdef UNDERWATER_MAP
	#else
	src.name = ocean_name
	#endif

	if(ocean_color)
		var/fluid_color = hex_to_rgb_list(ocean_color)
		light_r = fluid_color[1] / 255
		light_g = fluid_color[2] / 255
		light_b = fluid_color[3] / 255

	//let's replicate old behavior
	if(generateLight)
		generateLight = FALSE
		if (z != 3) //nono z3
			for (var/dir in alldirs)
				var/turf/T = get_step(src,dir)
				if (istype(T, /turf/simulated))
					generateLight = TRUE
					break

	if (generateLight)
		START_TRACKING_CAT(TR_CAT_LIGHT_GENERATING_TURFS)


/turf/space/fluid/Del()
	. = ..()
	if (generateLight)
		STOP_TRACKING_CAT(TR_CAT_LIGHT_GENERATING_TURFS)


/turf/space/fluid/make_light()
	if(!light)
		light = new
		light.attach(src)
	light.set_brightness(light_brightness)
	light.set_color(light_r, light_g, light_b)
	light.set_height(light_height)
	light.enable()


/turf/space/fluid/proc/bake_light()
	sleep(0.1 SECONDS)
	for(var/obj/overlay/tile_effect/lighting/L in src)
		src.icon = getFlatIcon(L)
		qdel(L)

/turf/space/fluid/proc/update_light()
	if(!light)
		return

	light.disable()
	light.set_brightness(light_brightness)
	light.set_color(light_r, light_g, light_b)
	light.set_height(light_height)
	light.enable()


//space/fluid/ReplaceWith() this is for future ctrl Fs
/turf/space/fluid/ReplaceWith(what, keep_old_material = TRUE, handle_air = TRUE, handle_dir = NORTH, force = FALSE)
	. = ..(what, keep_old_material, handle_air)

	if(handle_air)
		for(dir in global.cardinal)
			var/turf/space/fluid/T = get_step(src, dir)
			if(istype(T))
				T.tilenotify(src)

	if(src in processing_fluid_turfs)
		processing_fluid_turfs.Remove(src)


/turf/space/fluid/generate_worldgen()
	if(istype(src.loc, /area/shuttle))
		return

	if(HAS_FLAG(spawningFlags, SPAWN_DECOR))
		if(src.z == 5)
			if(prob(1))
				new /obj/item/seashell(src)
		else
			if(prob(5))
				new /obj/item/seashell(src)

	if(HAS_FLAG(spawningFlags, SPAWN_PLANTS))
		if(prob(8))
			var/obj/plant = pick(src.z == 5 ? childrentypesof(/obj/sea_plant) : (childrentypesof(/obj/sea_plant) - /obj/sea_plant/anemone/lit))
			var/obj/sea_plant/P = new plant(src)
			//mbc : bleh init() happens BFORRE this, most likely
			P.initialize()

	if(HAS_FLAG(spawningFlags, SPAWN_PLANTSMANTA))
		if(prob(8))
			var/obj/plant = pick(src.z == 5 ? childrentypesof(/obj/sea_plant_manta) : (childrentypesof(/obj/sea_plant_manta) - /obj/sea_plant_manta/anemone/lit))
			var/obj/sea_plant_manta/P = new plant(src)
			//mbc : bleh init() happens BFORRE this, most likely
			P.initialize()

	if(HAS_FLAG(spawningFlags, SPAWN_ACID_DOODADS))
		if(prob(8))
			var/obj/doodad = pick(childrentypesof(/obj/nadir_doodad))
			var/obj/nadir_doodad/D = new doodad(src)
			D.initialize()

	#ifndef UPSCALED_MAP
	if(HAS_FLAG(spawningFlags, SPAWN_FISH)) //can spawn bad fishy
		if(src.z == 5 && prob(1) && prob(2))
			new /obj/critter/gunbot/drone/buzzdrone/fish(src)
		else if(src.z == 5 && prob(1) && prob(4))
			new /obj/critter/gunbot/drone/gunshark(src)
		else if(prob(1) && prob(20))
			var/mob/fish = pick(childrentypesof(/mob/living/critter/aquatic/fish))
			new fish(src)
		else if(src.z == 5 && prob(1) && prob(9) && prob(90))
			var/obj/naval_mine/O = 0
			if(prob(20))
				if(prob(70))
					O = new /obj/naval_mine/standard(src)
				else
					O = new /obj/naval_mine/vandalized(src)
			else
				O = new /obj/naval_mine/rusted(src)
			if(O)
				O.initialize()
	#endif

	if(HAS_FLAG(spawningFlags, SPAWN_TRILOBITE))
		if(prob(17))
			new /obj/overlay/tile_effect/cracks/spawner/trilobite(src)
		if (prob(2))
			new /obj/overlay/tile_effect/cracks/spawner/pikaia(src)

	if(HAS_FLAG(spawningFlags, SPAWN_HALLU))
		if(prob(1) && prob(16))
			new /mob/living/critter/small_animal/hallucigenia(src)
		else if(prob(1) && prob(18))
			new /obj/overlay/tile_effect/cracks/spawner/pikaia(src)

	if(HAS_FLAG(spawningFlags, SPAWN_HOSTILE)) //nothing good comes from acid-washed depths...
		if(src.z == Z_LEVEL_MINING && prob(0.04))
			new /obj/critter/gunbot/drone/buzzdrone(src)
		else if(src.z == Z_LEVEL_MINING && prob(0.02))
			new /obj/critter/gunbot/drone/cutterdrone(src)
		else if(src.z == Z_LEVEL_MINING && prob(0.005))
			new /obj/critter/ancient_thing(src)

	if(HAS_FLAG(spawningFlags, SPAWN_LOOT))
		if (prob(1) && prob(9))
			var/obj/storage/crate/trench_loot/C = pick(childrentypesof(/obj/storage/crate/trench_loot))
			var/obj/storage/crate/trench_loot/created_loot = new C(src)
			created_loot.initialize()


/turf/space/fluid/levelupdate()
	for(var/obj/O in src)
		if(O.level == UNDERFLOOR)
			O.hide(FALSE)


/turf/space/fluid/tilenotify(turf/notifier)
	if(istype(notifier, /turf/space))
		return

	if(notifier.ocean_canpass())
		processing_fluid_turfs |= src
	else
		if(processing_fluid_turfs.Remove(src) && src.light)
			src.light.disable()


/turf/space/fluid/Entered(atom/movable/A) //MBC : I was too hurried and lazy to make this actually apply reagents on touch. this is a note to myself. FUCK YOUUU
	..()
	if(A.getStatusDuration("burning"))
		A.changeStatus("burning", -50 SECONDS)

	A.EnteredFluid(ocean_fluid_obj, A.loc)

	//nah disable for now i dont wanna do istype checks on enter
	//else if(isitem(A))
	//	var/obj/item/O = A
	//	if(O.burning && prob(40))
	//		O.burning = 0


/turf/space/fluid/Exited(atom/movable/Obj, atom/newloc)
	. = ..()
	Obj.ExitedFluid(Obj, newloc)


/turf/space/fluid/proc/force_mob_to_ingest(mob/M, mult = 1)//called when mob is drowning
	if(QDELETED(M))
		return

	var/react_volume = 50 * mult
	if(M.reagents)
		react_volume = min(react_volume, abs(M.reagents.maximum_volume - M.reagents.total_volume)) //don't push out other reagents if we are full
		M.reagents.add_reagent(ocean_reagent_id, react_volume) //todo : maybe add temp var here too


/turf/space/fluid/attackby(obj/item/C, mob/user, params) //i'm sorry
	if(istype(C, /obj/item/cable_coil))
		var/obj/item/cable_coil/coil = C
		coil.turf_place(src, get_turf(user), user)
	..()


/turf/space/fluid/ex_act(severity)
	..()
	if(captured)
		return

	if(!prob(severity * 20))
		for(var/obj/O in src)
			if(istype(O, /obj/lattice) || istype(O, /obj/cable/reinforced) || istype(O, /obj/item/heat_dowsing) || istype(O, /obj/machinery/conveyor) || istype(O,/obj/item/cable_coil/reinforced))
				return

		blow_hole()


/turf/space/fluid/proc/blow_hole()
	if(src.z != 5 && allow_hole)
		src.ReplaceWith(/turf/space/fluid/warp_z5/realwarp, FALSE, TRUE, FALSE, TRUE)


//////////////////////duh look below
/turf/space/fluid/warp_z5

	name = "deep hole"
	icon_state = "pit"
	spawningFlags = 0
	randomIcon = FALSE
	generateLight = FALSE

	allow_hole = FALSE

	color = OCEAN_COLOR
	fullbright = TRUE

	occlude_foreground_parallax_layers = TRUE
	fulltile_foreground_parallax_occlusion_overlay = TRUE



/turf/space/fluid/warp_z5/New()
	. = ..()
	for(var/obj/venthole/hole in src)
		qdel(hole)

	var/noise_scale = 55
	var/r1 = text2num(rustg_noise_get_at_coordinates("[global.server_start_time]", "[src.x / noise_scale]", "[src.y / noise_scale]"))
	var/r2 = text2num(rustg_noise_get_at_coordinates("[global.server_start_time + 123465]", "[src.x / noise_scale]", "[src.y / noise_scale]"))
	var/col = rgb(255 * (1 - r1 - r2), 255 * r2, 255 * r1)
	UpdateIcon(90, col)
	src.initialise_component()

/turf/space/fluid/warp_z5/proc/initialise_component()
	src.AddComponent(/datum/component/pitfall/target_area,\
		BruteDamageMax = 6,\
		FallTime = 0.3 SECONDS,\
		TargetArea = /area/trench_landing)

/turf/space/fluid/warp_z5/edge
	icon_state = "pit_wall"

/turf/space/fluid/warp_z5/New()
	. = ..()
	START_TRACKING

/turf/space/fluid/warp_z5/Del()
	STOP_TRACKING
	. = ..()



/turf/space/fluid/warp_z5/realwarp/New()
	..()
	src.initialise_component()
	if (!istype(get_step(src, NORTH), /turf/space/fluid/warp_z5/realwarp))
		icon_state = "pit_wall"

	var/turf/space/fluid/under = get_step(src, SOUTH)
	if (istype(under, /turf/space/fluid/warp_z5/realwarp))
		under.icon_state = "pit"

/turf/space/fluid/warp_z5/realwarp/initialise_component()
	src.AddComponent(/datum/component/pitfall/target_coordinates,\
		BruteDamageMax = 6,\
		FallTime = 0.3 SECONDS,\
		TargetZ = 5,\
		LandingRange = 8)



//trench floor
/turf/space/fluid/trench
	name = "trench floor"
	temperature = TRENCH_TEMP
	fullbright = 0
	luminosity = 1
	generateLight = 0
	allow_hole = 0
#ifdef MAP_OVERRIDE_NADIR
	spawningFlags = SPAWN_LOOT | SPAWN_HOSTILE | SPAWN_ACID_DOODADS
#else
	spawningFlags = SPAWN_DECOR | SPAWN_PLANTS | SPAWN_FISH | SPAWN_LOOT | SPAWN_HALLU
#endif
/turf/space/fluid/trench/blow_hole()
	if(src.z == 5)
		for(var/turf/space/fluid/T in range(1, locate(src.x, src.y, 1)))
			if(T.allow_hole)
				var/x = T.x
				var/y = T.y
				T.blow_hole()
				var/turf/space/fluid/warp_z5/hole = locate(x, y, 1)
				if(istype(hole))
					var/datum/component/pitfall/target_coordinates/getcomp = hole.GetComponent(/datum/component/pitfall/target_coordinates)
					getcomp.TargetList = list(src)
					src.linked_hole = hole
					src.add_simple_light("trenchhole", list(120, 120, 120, 120))
					break



/turf/space/fluid/trench/nospawn
	spawningFlags = null

/turf/space/fluid/trench/nospawn/generate_worldgen()
	return



/turf/space/fluid/nospawn
	spawningFlags = null

/turf/space/fluid/nospawn/generate_worldgen()
	return



/turf/space/fluid/noexplosion
	allow_hole = 0

/turf/space/fluid/noexplosion/ex_act(severity)
	return



/turf/space/fluid/noexplosion/nospawn
	spawningFlags = null

/turf/space/fluid/noexplosion/nospawn/ex_act(severity)
	return



//cenote for the biodome area
/turf/space/fluid/cenote
	fullbright = FALSE
	luminosity = 1
	generateLight = FALSE
	spawningFlags = null
	allow_hole = FALSE
	icon_state = "cenote"
	name = "cenote"
	desc = "A deep flooded sinkhole."
	randomIcon = FALSE

/turf/space/fluid/cenote/New()
	..()
	src.set_dir(pick(NORTH, SOUTH))


/turf/space/fluid/cenote/ex_act(severity)
	return



//full bright, used by oceanify on space maps
/turf/space/fluid/fullbright
	fullbright = TRUE



//Manta
/turf/space/fluid/manta
	luminosity = 1
	generateLight = FALSE
	spawningFlags = SPAWN_PLANTSMANTA
	turf_flags = CAN_BE_SPACE_SAMPLE | MANTA_PUSH



//Manta
/turf/space/fluid/manta/nospawn
	spawningFlags = null



/turf/simulated/floor/specialroom/sea_elevator_shaft
	name = "elevator shaft"
	desc = "It looks like it goes down a long ways."
	icon_state = "moon_shaft"
	var/const/area_type = /area/shuttle/sea_elevator/upper

/turf/simulated/floor/specialroom/sea_elevator_shaft/New()
	..()
	src.AddComponent(/datum/component/pitfall/target_landmark,\
		BruteDamageMax = 25,\
		FallTime = 0 SECONDS,\
		TargetLandmark = LANDMARK_FALL_SEA)

	var/turf/n = get_step(src,NORTH)
	var/turf/e = get_step(src,EAST)
	var/turf/w = get_step(src,WEST)
	var/turf/s = get_step(src,SOUTH)

	if(!istype(get_area(n), area_type))
		n = null
	if(!istype(get_area(e), area_type))
		e = null
	if(!istype(get_area(w), area_type))
		w = null
	if(!istype(get_area(s), area_type))
		s = null

	if(e && s)
		set_dir(SOUTH)
		e.set_dir(NORTH)
		s.set_dir(WEST)
	else if(e && n)
		set_dir(WEST)
		e.set_dir(EAST)
		n.set_dir(SOUTH)
	else if(w && s)
		set_dir(NORTH)
		w.set_dir(SOUTH)
		s.set_dir(EAST)
	else if(w && n)
		set_dir(EAST)
		w.set_dir(WEST)
		n.set_dir(NORTH)

/turf/simulated/floor/specialroom/sea_elevator_shaft/ex_act(severity)
	return



/turf/space/fluid/acid
	name = "acid sea floor"
	spawningFlags = SPAWN_ACID_DOODADS
	generateLight = 0
	temperature = TRENCH_TEMP

/turf/space/fluid/acid/clear
	spawningFlags = null
#ifdef IN_MAP_EDITOR
	icon_state = "concrete"
#endif


#undef SPAWN_DECOR
#undef SPAWN_PLANTS
#undef SPAWN_FISH
#undef SPAWN_PLANTSMANTA
