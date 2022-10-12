
/datum/targetable/critter/bury_hide
	name = "Bury Self"
	desc = "Hide yourself underground."
	cooldown = 3 SECONDS
	start_on_cooldown = 0
	icon_state = "tears"

/datum/targetable/critter/bury_hide/cast(atom/target)
	if (..())
		return TRUE

	var/turf/T = get_turf(holder.owner)
	if(T == holder.owner.loc)
		playsound(T, 'sound/effects/shovel1.ogg', 50, TRUE, 0.3)
		holder.owner.visible_message(
			"<span class='notice'><b>[holder.owner]</b> buries themselves!</span>",
			"<span class='notice'>You bury yourself.</span>",
		)

		var/obj/overlay/tile_effect/cracks/C = new(T)
		holder.owner.set_loc(C)

		if (holder.owner.ai)
			holder.owner.ai.enabled = 0
			holder.owner.ai.stop_move()


/obj/overlay/tile_effect/cracks
	icon = 'icons/effects/effects.dmi'
	icon_state = "cracks"
	event_handler_flags = USE_PROXIMITY

/obj/overlay/tile_effect/cracks/HasProximity(atom/movable/AM)
	..()
	if (isliving(AM))
		src.relaymove(AM,pick(cardinal))

/obj/overlay/tile_effect/cracks/relaymove(var/mob/user, direction)
	playsound(src, 'sound/effects/shovel1.ogg', 50, TRUE, 0.3)
	for (var/mob/M in src)
		if (M.ai)
			M.ai.enabled = TRUE
		M.set_loc(src.loc)
	qdel(src)


/obj/overlay/tile_effect/cracks/spawner
	var/spawntype = null


/obj/overlay/tile_effect/cracks/spawner/HasProximity(atom/movable/AM)
	if (spawntype)
		new spawntype(src)
		spawntype = null
	..()

/obj/overlay/tile_effect/cracks/spawner/trilobite
	spawntype = /mob/living/critter/small_animal/trilobite/ai_controlled

/obj/overlay/tile_effect/cracks/spawner/pikaia
	spawntype = /mob/living/critter/small_animal/pikaia/ai_controlled


///obj/overlay/tile_effect/cracks/trilobite
///obj/overlay/tile_effect/cracks/pikaia
