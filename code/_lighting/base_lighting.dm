/image/fullbright
	icon = 'icons/effects/white.dmi'
	plane = PLANE_LIGHTING
	layer = LIGHTING_LAYER_FULLBRIGHT
	blend_mode = BLEND_OVERLAY
	appearance_flags = PIXEL_SCALE | TILE_BOUND | RESET_ALPHA | RESET_COLOR

/image/ambient
	icon = 'icons/effects/white.dmi'
	plane = PLANE_LIGHTING
	layer = LIGHTING_LAYER_BASE
	blend_mode = BLEND_ADD
	appearance_flags = PIXEL_SCALE | TILE_BOUND | RESET_ALPHA | RESET_COLOR

/obj/ambient
	icon = 'icons/effects/white.dmi'
	plane = PLANE_LIGHTING
	layer = LIGHTING_LAYER_BASE
	blend_mode = BLEND_ADD
	appearance_flags = PIXEL_SCALE | TILE_BOUND | RESET_ALPHA | RESET_COLOR


/area
	/// If TRUE, all turfs in the area will be fullbright.
	var/force_fullbright = FALSE
	/// Color of the ambient light in the area. If null, no ambient light is applied.
	var/ambient_light = null //rgb(0.025 * 255, 0.025 * 255, 0.025 * 255)

	New()
		..()
		if (force_fullbright)
			src.AddOverlays(new /image/fullbright, "fullbright")
		else if (ambient_light)
			var/image/I = new /image/ambient
			I.color = ambient_light
			src.AddOverlays(I, "ambient")

	proc/update_fullbright()
		if (force_fullbright)
			src.AddOverlays(new /image/fullbright, "fullbright")
		else
			src.ClearSpecificOverlays("fullbright")
			for (var/turf/T as anything in src)
				T.RL_Init()

/turf
	luminosity = 1
	var/fullbright = 0

/turf/proc/init_lighting()
	var/area/A = loc

	#ifdef UNDERWATER_MAP //FUCK THIS SHIT. NO FULLBRIGHT ON THE MINING LEVEL, I DONT CARE.
	if (z == AST_ZLEVEL) return
	#endif

	// space handles its own lighting via simple lights which already cover the turf itself too
	if (!istype(src, /turf/space) && !A.force_fullbright && fullbright) // if the area's fullbright we'll use a single overlay on the area instead
		src.AddOverlays(new /image/fullbright, "fullbright")
