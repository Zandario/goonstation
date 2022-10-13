var/datum/action_controller/actions

//See _setup.dm for interrupt and state definitions

/datum/action_controller
	var/list/running = list() //Associative list of running actions, format: owner=list of action datums

/// Has this mob an action of a given type running?
/datum/action_controller/proc/hasAction(atom/owner, id)
	if(owner in running)
		var/list/actions = running[owner]
		for(var/datum/action/A in actions)
			if(A.id == id)
				return 1
	return 0

/// Interrupts all actions of a given owner.
/datum/action_controller/proc/stop_all(atom/owner)
	if(owner in running)
		for(var/datum/action/A in running[owner])
			A.interrupt(INTERRUPT_ALWAYS)
	return

/// Manually interrupts a given action of a given owner.
/datum/action_controller/proc/stop(datum/action/A, atom/owner)
	if(owner in running)
		var/list/actions = running[owner]
		if(A in actions)
			A.interrupt(INTERRUPT_ALWAYS)
	return

/// Manually interrupts a given action id of a given owner.
/datum/action_controller/proc/stopId(id, atom/owner)
	if(owner in running)
		var/list/actions = running[owner]
		for(var/datum/action/A in actions)
			if(A.id == id)
				A.interrupt(INTERRUPT_ALWAYS)
	return

/// Starts a new action.
/datum/action_controller/proc/start(datum/action/A, atom/owner)
	if(!owner)
		qdel(A)
		return
	if(!(owner in running))
		running.Add(owner)
		running[owner] = list(A)
	else
		interrupt(owner, INTERRUPT_ACTION)
		for(var/datum/action/OA in running[owner])
			//Meant to catch users starting the same action twice, and saving the first-attempt from deletion
			if(OA.id == A.id && OA.state == ACTIONSTATE_DELETE && (OA.interrupt_flags & INTERRUPT_ACTION) && OA.resumable)
				OA.onResume(A)
				qdel(A)
				return OA
		running[owner] += A
	A.owner = owner
	A.started = TIME
	A.onStart()
	return A // cirr here, I added action ref to the return because I need it for AI stuff, thank you

/// Is called by all kinds of things to check for action interrupts.
/datum/action_controller/proc/interrupt(atom/owner, flag)
	if(owner in running)
		for(var/datum/action/A in running[owner])
			A.interrupt(flag)
	return

/// Handles the action countdowns, updates and deletions.
/datum/action_controller/proc/process()
	for(var/X in running)
		for(var/datum/action/A in running[X])

			if( ((A.duration >= 0 && TIME >= (A.started + A.duration)) && A.state == ACTIONSTATE_RUNNING) || A.state == ACTIONSTATE_FINISH)
				A.state = ACTIONSTATE_ENDED
				A.onEnd()
				//continue //If this is not commented out the deletion will take place the tick after the action ends. This will break things like objects being deleted onEnd with progressbars - the bars will be left behind. But it will look better for things that do not do this.

			if(A.state == ACTIONSTATE_DELETE || A.disposed)
				A.onDelete()
				running[X] -= A
				continue

			A.onUpdate()

		if(length(running[X]) == 0)
			running.Remove(X)
	return

/datum/action
	/// Object that owns this action.
	var/atom/owner = null
	/// How long does this action take in ticks.
	var/duration = 1
	/// When and how this action is interrupted.
	var/interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	/// Current state of the action.
	var/state = ACTIONSTATE_STOPPED
	/// TIME this action was started at.
	var/started = -1
	/// Unique ID for this action. For when you want to remove actions by ID on a person.
	var/id = "base"
	var/resumable = TRUE

/// This is called by the default interrupt actions.
/datum/action/proc/interrupt(flag)
	if(interrupt_flags & flag || flag == INTERRUPT_ALWAYS)
		state = ACTIONSTATE_INTERRUPTED
		onInterrupt(flag)
	return

/**
 * Called every tick this action is running.
 * If you absolutely(!!!) have to you can do manual interrupt checking in here.
 * Otherwise this is mostly used for drawing progress bars and shit.
 */
/datum/action/proc/onUpdate()
	return

/// Called when the action fails / is interrupted.
/datum/action/proc/onInterrupt(flag = 0)
	state = ACTIONSTATE_DELETE
	return

/// Called when the action begins.
/datum/action/proc/onStart()
	state = ACTIONSTATE_RUNNING
	return

/// Called when the action restarts (for example: automenders).
/datum/action/proc/onRestart()
	sleep(1)
	started = TIME
	state = ACTIONSTATE_RUNNING
	loopStart()
	return

/// Called after restarting. Meant to cotain code from -and be called from- onStart().
/datum/action/proc/loopStart()
	return

/// Called when the action resumes - likely from almost ending. Arg is the action which would have cancelled this.
/datum/action/proc/onResume(datum/action/attempted)
	state = ACTIONSTATE_RUNNING
	return

/// Called when the action succesfully ends.
/datum/action/proc/onEnd()
	state = ACTIONSTATE_DELETE
	return

/// Called when the action is complete and about to be deleted. Usable for cleanup and such.
/datum/action/proc/onDelete()
	return

/// Updates the animations.
/datum/action/proc/updateBar()
	return

/// This subclass has a progressbar that attaches to the owner to show how long we need to wait.
/datum/action/bar
	var/obj/actions/bar/bar
	var/obj/actions/border/border
	var/obj/actions/bar/target_bar
	var/obj/actions/border/target_border
	var/bar_icon_state = "bar"
	var/border_icon_state = "border"
	var/color_active = "#4444FF"
	var/color_success = "#00CC00"
	var/color_failure = "#CC0000"
	/// By default the bar is put on the owner, define this on the progress bar as the place you want to put it on.
	var/atom/movable/place_to_put_bar = null
	/// In case we want the owner to have no visible action bar but still want to make the bar.
	var/bar_on_owner = TRUE
	/// Does bar fill or empty?
	var/fill_bar = TRUE


/datum/action/bar/onStart()
	..()
	var/atom/movable/A = owner
	if(owner != null)
		bar = new /obj/actions/bar
		border = new /obj/actions/border
		border.set_icon_state(src.border_icon_state)
		bar.set_icon_state(src.bar_icon_state)
		bar.pixel_y = 5
		bar.pixel_x = 0
		border.pixel_y = 5
		if (bar_on_owner)
			A.vis_contents += bar
			A.vis_contents += border
		if (place_to_put_bar)
			target_bar = new /obj/actions/bar
			target_border = new /obj/actions/border
			target_border.set_icon_state(src.border_icon_state)
			target_bar.set_icon_state(src.bar_icon_state)
			target_bar.pixel_y = 5
			target_bar.pixel_x = 0
			target_border.pixel_y = 5
			place_to_put_bar.vis_contents += target_bar
			place_to_put_bar.vis_contents += target_border

		// this will absolutely obviously cause no problems.
		bar.color = src.color_active
		if (target_bar)
			target_bar.color = src.color_active
		updateBar()

/datum/action/bar/onRestart()
	//Start the bar back at 0
	bar.transform = matrix(0, 0, -15, 0, 1, 0)
	if (target_bar)
		target_bar.transform = matrix(0, 0, -15, 0, 1, 0)
	..()

/datum/action/bar/onDelete()
	..()
	var/atom/movable/A = owner
	if (owner && bar_on_owner)
		A.vis_contents -= bar
		A.vis_contents -= border
	if (place_to_put_bar)
		place_to_put_bar.vis_contents -= target_bar
		place_to_put_bar.vis_contents -= target_border
	SPAWN(0.5 SECONDS)
		if (bar)
			bar.set_loc(null)
			qdel(bar)
			bar = null
		if (border)
			border.set_loc(null)
			qdel(border)
			border = null
		if (target_bar)
			target_bar.set_loc(null)
			qdel(target_bar)
			target_bar = null
		if (target_border)
			target_border.set_loc(null)
			qdel(target_border)
			target_border = null

/datum/action/bar/disposing()
	var/atom/movable/A = owner
	if (owner && bar_on_owner)
		A.vis_contents -= bar
		A.vis_contents -= border
	if (place_to_put_bar)
		place_to_put_bar.vis_contents -= target_bar
		place_to_put_bar.vis_contents -= target_border
	if (bar)
		bar.set_loc(null)
		qdel(bar)
		bar = null
	if (border)
		border.set_loc(null)
		qdel(border)
		border = null
	if (target_bar)
		target_bar.set_loc(null)
		qdel(target_bar)
		target_bar = null
	if (target_border)
		target_border.set_loc(null)
		qdel(target_border)
		target_border = null
	..()

/datum/action/bar/onEnd()
	if (bar)
		bar.color = "#FFFFFF"
		animate( bar, color = src.color_success, time = 2.5 , flags = ANIMATION_END_NOW)
		bar.transform = matrix() //Tiny cosmetic fix. Makes it so the bar is completely filled when the action ends.
	if (target_bar)
		target_bar.color = "#FFFFFF"
		animate( target_bar, color = src.color_success, time = 2.5 , flags = ANIMATION_END_NOW)
		target_bar.transform = matrix() //Tiny cosmetic fix. Makes it so the target's bar is completely filled when the action ends.
	..()

/datum/action/bar/onInterrupt(flag)
	if(state != ACTIONSTATE_DELETE)
		if (bar)
			updateBar(0)
			bar.color = "#FFFFFF"
			animate( bar, color = src.color_failure, time = 2.5 )
		if (target_bar)
			updateBar(0)
			target_bar.color = "#FFFFFF"
			animate( target_bar, color = src.color_failure, time = 2.5 )
	..()

/datum/action/bar/onResume(datum/action/attempted)
	if (bar)
		updateBar()
		bar.color = src.color_active
	if (target_bar)
		updateBar()
		target_bar.color = src.color_active
	..()

/datum/action/bar/onUpdate()
	updateBar()
	..()

/datum/action/bar/updateBar(animate = 1)
	if (duration <= 0 || isnull(bar))
		return
	var/done = TIME - started
	// inflate it a little to stop it from hitting 100% "too early"
	var/fakeduration = duration + ((animate && done < duration) ? (world.tick_lag * 7) : 0)
	var/remain = max(0, fakeduration - done)
	var/complete = clamp(done / fakeduration, 0, 1)
	if(!fill_bar)
		complete = 1 - complete
	bar.transform = matrix(complete, 0, -15 * (1 - complete), 0, 1, 0)
	if (target_bar)
		target_bar.transform = matrix(complete, 0, -15 * (1 - complete), 0, 1, 0)
	if (animate)
		if(fill_bar)
			animate( bar, transform = matrix(1, 0, 0, 0, 1, 0), time = remain )
			if (target_bar)
				animate( target_bar, transform = matrix(1, 0, 0, 0, 1, 0), time = remain )
		else
			animate( bar, transform = matrix(0, 0, -15, 0, 1, 0), time = remain )
			if (target_bar)
				animate( target_bar, transform = matrix(0, 0, -15, 0, 1, 0), time = remain )
	else
		animate( bar, flags = ANIMATION_END_NOW )
		if (target_bar)
			animate( target_bar, flags = ANIMATION_END_NOW )
	return

/datum/action/bar/blob_health // WOW HACK
	bar_icon_state = "bar-blob"
	border_icon_state = "border-blob"
	color_active = "#9eee80"
	color_success = "#167935"
	color_failure = "#8d1422"

/datum/action/bar/blob_health/onUpdate()
	var/obj/blob/B = owner
	if (!owner || !istype(owner) || !bar || !border) //Wire note: Fix for Cannot modify null.invisibility
		return
	if (B.health == B.health_max)
		border.invisibility = INVIS_ALWAYS
		bar.invisibility = INVIS_ALWAYS
	else
		border.invisibility = INVIS_NONE
		bar.invisibility = INVIS_NONE
	var/complete = B.health / B.health_max
	bar.color = "#00FF00"
	bar.transform = matrix(complete, 1, MATRIX_SCALE)
	bar.pixel_x = -nround( ((30 - (30 * complete)) / 2) )

/datum/action/bar/bullethell
	var/obj/actions/bar/shield_bar
	var/obj/actions/bar/armor_bar

/datum/action/bar/bullethell/onStart()
	..()
	var/atom/movable/A = owner
	if(owner != null)
		shield_bar = new /obj/actions/bar
		shield_bar.loc = owner.loc
		armor_bar = new /obj/actions/bar
		armor_bar.loc = owner.loc
		shield_bar.pixel_y = 5
		armor_bar.pixel_y = 5
		if (!islist(A.attached_objs))
			A.attached_objs = list()
		A.attached_objs.Add(shield_bar)
		A.attached_objs.Add(armor_bar)
		shield_bar.layer = initial(shield_bar.layer) + 2
		armor_bar.layer = initial(armor_bar.layer) + 1

/datum/action/bar/bullethell/onDelete()
	..()
	shield_bar.invisibility = INVIS_NONE
	armor_bar.invisibility = INVIS_NONE
	bar.invisibility = INVIS_NONE
	border.invisibility = INVIS_NONE
	var/atom/movable/A = owner
	if (owner != null && islist(A.attached_objs))
		A.attached_objs.Remove(shield_bar)
		A.attached_objs.Remove(armor_bar)
	qdel(shield_bar)
	shield_bar = null
	qdel(armor_bar)
	armor_bar = null

/datum/action/bar/bullethell/onUpdate()
	var/obj/bullethell/B = owner
	if (!owner || !istype(owner))
		return
	var/h_complete = B.health / B.max_health
	bar.color = "#00FF00"
	bar.transform = matrix(h_complete, 1, MATRIX_SCALE)
	bar.pixel_x = -nround( ((30 - (30 * h_complete)) / 2) )
	if (B.max_armor && B.armor)
		armor_bar.invisibility = INVIS_NONE
		var/a_complete = B.armor / B.max_armor
		armor_bar.color = "#FF8800"
		armor_bar.transform = matrix(a_complete, 1, MATRIX_SCALE)
		armor_bar.pixel_x = -nround( ((30 - (30 * a_complete)) / 2) )
	else
		armor_bar.invisibility = INVIS_ALWAYS
	if (B.max_shield && B.shield)
		shield_bar.invisibility = INVIS_NONE
		var/s_complete = B.shield / B.max_shield
		shield_bar.color = "#3333FF"
		shield_bar.transform = matrix(s_complete, 1, MATRIX_SCALE)
		shield_bar.pixel_x = -nround( ((30 - (30 * s_complete)) / 2) )
	else
		shield_bar.invisibility = INVIS_ALWAYS


/datum/action/bar/icon //Visible to everyone and has an icon.
	var/icon //! Icon to use above the bar. Can also be a mutable_appearance; pretty much anything that can be converted into an image
	var/icon_state
	var/icon_y_off = 30
	var/icon_x_off = 0
	var/image/icon_image
	var/icon_plane = PLANE_HUD
	/// Is the icon also on the target if we have one? if this is TRUE, make sure the target only handles overlays by using the UpdateOverlays proc.
	var/icon_on_target = FALSE

/datum/action/bar/icon/onStart()
	..()
	if (icon && owner)
		if(icon_state)
			icon_image = image(icon, border, icon_state, 10)
		else
			icon_image = image(icon, border, layer = 10)
		icon_image.pixel_y = icon_y_off
		icon_image.pixel_x = icon_x_off
		icon_image.plane = icon_plane
		icon_image.filters += filter(type="outline", size=0.5, color=rgb(255,255,255))
		border.UpdateOverlays(icon_image, "action_icon")
		if (icon_on_target && place_to_put_bar)
			target_border.UpdateOverlays(icon_image, "action_icon")

/datum/action/bar/icon/onDelete()
	if (icon_on_target && place_to_put_bar && target_border)
		target_border.UpdateOverlays(null, "action_icon")
	if (border)
		border.UpdateOverlays(null, "action_icon")
	if (icon_image)
		qdel(icon_image)
	..()


/**
* calls a specified proc if it finishes without interruptions.
*
* check [_std/macros/actions.dm] for documentation on a macro that uses this.
*/
/datum/action/bar/icon/callback
	/// set to a string version of the callback proc path
	id = null
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	/// set to the path of the proc that will be called if the action bar finishes
	var/proc_path = null
	/// set to datum to perform callback on if seperate from owner or target
	var/call_proc_on = null
	/// what the target of the action is, if any
	var/target = null
	/// what string is broadcast once the action bar finishes
	var/end_message = ""
	/// what is the maximum range target and owner can be apart? need to modify before starting the action.
	var/maximum_range = 1
	/// a list of args for the proc thats called once the action bar finishes, if needed.
	var/list/proc_args = null

/datum/action/bar/icon/callback/New(owner, target, duration, proc_path, proc_args, icon, icon_state, end_message, interrupt_flags, call_proc_on)
	..()
	if (owner)
		src.owner = owner
	else //no owner means we have nothing to do things with
		CRASH("action bars need an owner object to be tied to")
	if (target) //not having a target is okay, sometimes were just doing things to ourselves
		src.target = target
	if (duration)
		src.duration = duration
	else //no duration dont do the thing
		CRASH("action bars need a duration to run for, there's no default duration")
	if (proc_path)
		src.proc_path = proc_path
	else //no proc, dont do the thing
		CRASH("no proc was specified to be called once the action bar ends")
	if(call_proc_on)
		src.call_proc_on = call_proc_on
	if (proc_args)
		src.proc_args = proc_args
	if (icon) //optional, dont always want an icon
		src.icon = icon
		if (icon_state) //optional, dont always want an icon state
			src.icon_state = icon_state
	else if (icon_state)
		CRASH("icon state set for action bar, but no icon was set")
	if (end_message)
		src.end_message = end_message
	if (interrupt_flags != null)
		src.interrupt_flags = interrupt_flags
	//generate a id
	if (src.proc_path)
		src.id = "[src.proc_path]"

	src.proc_args = proc_args

/datum/action/bar/icon/callback/onStart()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/icon/callback/onUpdate()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/icon/callback/onEnd()
	..()
	if (!src.proc_path)
		CRASH("action bar had no proc to call upon completion")
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

	if (end_message)
		src.owner.visible_message("[src.end_message]")
	if (src.call_proc_on)
		INVOKE_ASYNC(arglist(list(src.call_proc_on, src.proc_path) + src.proc_args))
	else if (src.target)
		INVOKE_ASYNC(arglist(list(src.target, src.proc_path) + src.proc_args))
	else
		INVOKE_ASYNC(arglist(list(src.owner, src.proc_path) + src.proc_args))

/**
 * Used when you need to make sure that mob is holding item.
 * Aaand is next to other thing while doing thing.
 */
/datum/action/bar/icon/hitthingwithitem
	/// What item is required to be held during it.
	var/helditem = null
	/// What mob is required to be holding the item.
	var/mob/holdingmob = null
	/// This was made for material compatibility, choose what to call the proc on.
	var/call_proc_on = null
	// Copy-Pasted from Adhara's generic action bar
	/// Set to a string version of the callback proc path.
	id = null
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	/// Set to the path of the proc that will be called if the action bar finishes.
	var/proc_path = null
	/// What the target of the action is, if any.
	var/target = null
	/// What string is broadcast once the action bar finishes.
	var/end_message = ""
	/// What is the maximum range target and owner can be apart? need to modify before starting the action.
	var/maximum_range = 1
	/// A list of args for the proc thats called once the action bar finishes, if needed.
	var/list/proc_args = null


/datum/action/bar/icon/hitthingwithitem/New(owner, mob/holdingmob, obj/item/helditem, target, call_proc_on, duration, proc_path, list/proc_args, icon, icon_state, end_message)
	..()
	if (owner)
		src.owner = owner
	else //no owner means we have nothing to do things with
		CRASH("action bars need an owner object to be tied to")
	if (holdingmob)
		src.holdingmob = holdingmob
	else
		CRASH("hitthingwithitem needs a mob to hold item")
	if (helditem)
		src.helditem = helditem
	else
		CRASH("hitthingwithitem needs an item to be held")
	if (target) //not having a target is okay, sometimes were just doing things to ourselves
		src.target = target
	if (call_proc_on)
		src.call_proc_on = call_proc_on // if we don't have a call_proc_on, we'll default to owner
	if (duration)
		src.duration = duration
	else //no duration dont do the thing
		CRASH("action bars need a duration to run for, there's no default duration")
	if (proc_path)
		src.proc_path = proc_path
	else //no proc, dont do the thing
		CRASH("no proc was specified to be called once the action bar ends")
	if (proc_args)
		src.proc_args = proc_args
	if (icon) //optional, dont always want an icon
		src.icon = icon
		if (icon_state) //optional, dont always want an icon state
			src.icon_state = icon_state
	else if (icon_state)
		CRASH("icon state set for action bar, but no icon was set")
	if (end_message)
		src.end_message = end_message

	//generate a id
	if (src.proc_path)
		src.id = "[src.proc_path]"

/datum/action/bar/icon/hitthingwithitem/onStart()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if ((src.target && !IN_RANGE(src.owner, src.target, src.maximum_range)) || holdingmob.equipped() != helditem)
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/icon/hitthingwithitem/onUpdate()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if ((src.target && !IN_RANGE(src.owner, src.target, src.maximum_range)) || holdingmob.equipped() != helditem)
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/icon/hitthingwithitem/onEnd()
	..()
	if (!src.proc_path)
		CRASH("action bar had no proc to call upon completion")
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if ((src.target && !IN_RANGE(src.owner, src.target, src.maximum_range)) || holdingmob.equipped() != helditem)
		interrupt(INTERRUPT_ALWAYS)

	src.owner.visible_message("[src.end_message]")
	if (src.call_proc_on)
		INVOKE_ASYNC(arglist(list(src.call_proc_on, src.proc_path) + src.proc_args))
	else
		INVOKE_ASYNC(arglist(list(src.owner, src.proc_path) + src.proc_args))
/datum/action/bar/icon/build
	duration = 30
	var/obj/item/sheet/sheet
	var/objtype
	var/cost
	var/datum/material/mat
	var/amount
	var/objname
	var/callback = null
	var/obj/item/sheet/sheet2 // in case you need to pull from more than one sheet
	var/cost2 // same as above
	var/spot

/datum/action/bar/icon/build/New(obj/item/sheet/csheet, cobjtype, ccost, datum/material/cmat, camount, cicon, cicon_state, cobjname, post_action_callback = null, obj/item/sheet/csheet2, ccost2, spot)
	..()
	icon = cicon
	icon_state = cicon_state
	sheet = csheet
	objtype = cobjtype
	cost = ccost
	mat = cmat
	amount = camount
	objname = cobjname
	callback = post_action_callback
	src.spot = spot
	if (csheet2)
		sheet2 = csheet2
	if (ccost2)
		cost2 = ccost2

/datum/action/bar/icon/build/onStart()
	..()
//You can't build! The if is to stop compiler warnings
#if defined(MAP_OVERRIDE_POD_WARS)
	if (owner)
		boutput(owner, "<span class='alert'>What are you gonna do with this? You have a very particular set of skills, and building is not one of them...</span>")
		interrupt(INTERRUPT_ALWAYS)
		return
#endif

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.traitHolder.hasTrait("carpenter") || H.traitHolder.hasTrait("training_engineer"))
			duration = round(duration / 2)

	if(QDELETED(sheet))
		boutput(owner, "<span class='notice'>You have nothing to build with!</span>")
		interrupt(INTERRUPT_ALWAYS)
		return

	owner.visible_message("<span class='notice'>[owner] begins assembling [objname]!</span>")

/datum/action/bar/icon/build/onUpdate()
	. = ..()
	if(QDELETED(sheet) || sheet.amount < cost)
		interrupt(INTERRUPT_ALWAYS)
	if (ismob(owner))
		var/mob/M = owner
		if(!equipped_or_holding(sheet, M))
			interrupt(INTERRUPT_ALWAYS)
			return

/datum/action/bar/icon/build/onEnd()
	..()
	if(QDELETED(sheet) || sheet.amount < cost)
		interrupt(INTERRUPT_ALWAYS)
		return
	if (ismob(owner))
		var/mob/M = owner
		if(!equipped_or_holding(sheet, M))
			interrupt(INTERRUPT_ALWAYS)
			return
	owner.visible_message("<span class='notice'>[owner] assembles [objname]!</span>")
	var/obj/item/R = new objtype(get_turf(spot || owner))
	R.setMaterial(mat)
	if (istype(R))
		R.amount = amount
		R.inventory_counter?.update_number(R.amount)
	R.set_dir(owner.dir)
	sheet.change_stack_amount(-cost)
	if (sheet2 && cost2)
		sheet2.change_stack_amount(-cost2)
	logTheThing(LOG_STATION, owner, "builds [objname] (<b>Material:</b> [mat && istype(mat) && mat.mat_id ? "[mat.mat_id]" : "*UNKNOWN*"]) at [log_loc(owner)].")
	if(isliving(owner))
		var/mob/living/M = owner
		R.add_fingerprint(M)
	if (callback)
		call(callback)(src, R)

/datum/action/bar/icon/cruiser_repair
	id = "genproc"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	duration = 30
	icon = 'icons/ui/actions.dmi'
	icon_state = "working"

	var/obj/machinery/cruiser_destroyable/repairing
	var/obj/item/using

/datum/action/bar/icon/cruiser_repair/New(obj/machinery/cruiser_destroyable/D, obj/item/U, duration_i)
	..()
	repairing = D
	using = U
	duration = duration_i

/datum/action/bar/icon/cruiser_repair/onUpdate()
	..()
	if(BOUNDS_DIST(owner, repairing) > 0 || repairing == null || owner == null || using == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	var/mob/source = owner
	if(using != source.equipped())
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/icon/cruiser_repair/onStart()
	..()
	owner.visible_message("<span class='notice'>[owner] begins repairing [repairing]!</span>")

/datum/action/bar/icon/cruiser_repair/onEnd()
	..()
	owner.visible_message("<span class='notice'>[owner] successfully repairs [repairing]!</span>")
	repairing.adjustHealth(repairing.health_max)

/// This subclass is only visible to the owner of the action.
/datum/action/bar/private
	border_icon_state = "border-private"

/datum/action/bar/private/onStart()
	..()
	if (ismob(owner))
		var/mob/M = owner
		bar.icon = null
		border.icon = null
		M.client?.images += bar.img
		M.client?.images += border.img
		if(place_to_put_bar)
			target_bar.icon = null
			target_border.icon = null
			M.client?.images += target_bar.img
			M.client?.images += target_border.img

/datum/action/bar/private/onDelete()
	bar.icon = 'icons/ui/actions.dmi'
	border.icon = 'icons/ui/actions.dmi'
	if (ismob(owner))
		var/mob/M = owner
		M.client?.images -= bar.img
		M.client?.images -= border.img
		qdel(bar.img)
		qdel(border.img)
		if(place_to_put_bar)
			M.client?.images -= target_bar.img
			M.client?.images -= target_border.img
			qdel(target_bar.img)
			qdel(target_border.img)
	..()

/// Only visible to the owner and has a little icon on the bar.
/datum/action/bar/private/icon
	var/icon
	var/icon_state
	var/icon_y_off = 30
	var/icon_x_off = 0
	var/image/icon_image
	var/icon_plane = PLANE_HUD

/datum/action/bar/private/icon/onStart()
	..()
	if(icon && icon_state && owner)
		icon_image = image(icon, owner, icon_state, 10)
		icon_image.pixel_y = icon_y_off
		icon_image.pixel_x = icon_x_off
		icon_image.plane = icon_plane

		icon_image.filters += filter(type="outline", size=0.5, color=rgb(255,255,255))
		if (ismob(owner))
			var/mob/M = owner
			M.client?.images += icon_image

/datum/action/bar/private/icon/onDelete()
	if (ismob(owner))
		var/mob/M = owner
		M.client?.images -= icon_image
	qdel(icon_image)
	..()

//ACTIONS
/**
 * Calls a specified proc if it finishes without interruptions. Only displayed to the user.
 * Heavily copy pasted from /datum/action/bar/icon/callback.
 *
 * check [_std/macros/actions.dm] for documentation on a macro that uses this.
 */
/datum/action/bar/private/icon/callback
	/// Set to a string version of the callback proc path.
	id = null
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	/// Set to the path of the proc that will be called if the action bar finishes.
	var/proc_path = null
	/// Set to datum to perform callback on if seperate from owner or target.
	var/call_proc_on = null
	/// What the target of the action is, if any.
	var/target = null
	/// What string is broadcast once the action bar finishes.
	var/end_message = ""
	/// What is the maximum range target and owner can be apart? need to modify before starting the action.
	var/maximum_range = 1
	/// A list of args for the proc thats called once the action bar finishes, if needed.
	var/list/proc_args = null

/datum/action/bar/private/icon/callback/New(owner, target, duration, proc_path, proc_args, icon, icon_state, end_message, interrupt_flags, call_proc_on)
	..()
	if (owner)
		src.owner = owner
	else //no owner means we have nothing to do things with
		CRASH("action bars need an owner object to be tied to")
	if (target) //not having a target is okay, sometimes were just doing things to ourselves
		src.target = target
	if (duration)
		src.duration = duration
	else //no duration dont do the thing
		CRASH("action bars need a duration to run for, there's no default duration")
	if (proc_path)
		src.proc_path = proc_path
	else //no proc, dont do the thing
		CRASH("no proc was specified to be called once the action bar ends")
	if(call_proc_on)
		src.call_proc_on = call_proc_on
	if (proc_args)
		src.proc_args = proc_args
	if (icon) //optional, dont always want an icon
		src.icon = icon
		if (icon_state) //optional, dont always want an icon state
			src.icon_state = icon_state
	else if (icon_state)
		CRASH("icon state set for action bar, but no icon was set")
	if (end_message)
		src.end_message = end_message
	if (interrupt_flags)
		src.interrupt_flags = interrupt_flags
	//generate a id
	if (src.proc_path)
		src.id = "[src.proc_path]"

	src.proc_args = proc_args

/datum/action/bar/private/icon/callback/onStart()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/private/icon/callback/onUpdate()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

/datum/action/bar/private/icon/callback/onEnd()
	..()
	if (!src.proc_path)
		CRASH("action bar had no proc to call upon completion")
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

	if (end_message)
		src.owner.visible_message("[src.end_message]")
	if (src.call_proc_on)
		INVOKE_ASYNC(arglist(list(src.call_proc_on, src.proc_path) + src.proc_args))
	else if (src.target)
		INVOKE_ASYNC(arglist(list(src.target, src.proc_path) + src.proc_args))
	else
		INVOKE_ASYNC(arglist(list(src.owner, src.proc_path) + src.proc_args))

#define STAM_COST 30
/// Putting items on or removing items from others.
/datum/action/bar/icon/otherItem
	id = "otheritem"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	icon = 'icons/mob/screen1.dmi'
	icon_state = "grabbed"

	/// The mob doing the action.
	var/mob/living/source
	/// The target of the action.
	var/mob/living/carbon/human/target
	/// The item if any. If theres no item, we tried to remove something from that slot instead of putting an item there.
	var/obj/item/item
	/// The slot number.
	var/slot
	var/hidden


/datum/action/bar/icon/otherItem/New(Source, Target, Item, Slot, ExtraDuration = 0, Hidden = 0)
	source = Source
	target = Target
	item = Item
	slot = Slot
	hidden = Hidden

	if(item)
		if(item.duration_put > 0)
			duration = item.duration_put
		else
			duration = 4.5 SECONDS
	else
		var/obj/item/I = target.get_slot(slot)
		if(I)
			if(I.duration_remove > 0)
				duration = I.duration_remove
			else
				duration = 2.5 SECONDS

	duration += ExtraDuration

	if(source.reagents && source.reagents.has_reagent("crime"))
		duration /= 5
	..()

/datum/action/bar/icon/otherItem/onStart()

	target.add_fingerprint(source) // Added for forensics (Convair880).

	if (source.mob_flags & AT_GUNPOINT)
		for(var/obj/item/grab/gunpoint/G in source.grabbed_by)
			G.shoot()

	if (source.use_stamina && source.get_stamina() < STAM_COST)
		boutput(owner, "<span class='alert>You're too winded to [item ? "place that on" : "take that from"] [him_or_her(target)].</span>")
		src.resumable = FALSE
		interrupt(INTERRUPT_ALWAYS)
		return
	source.remove_stamina(STAM_COST)

	if(item)
		if(!target.can_equip(item, slot))
			boutput(source, "<span class='alert'>[item] can not be put there.</span>")
			interrupt(INTERRUPT_ALWAYS)
			return
		if(!isturf(target.loc))
			boutput(source, "<span class='alert'>You can't put [item] on [target] when [(he_or_she(target))] is in [target.loc]!</span>")
			interrupt(INTERRUPT_ALWAYS)
			return
		if(item.cant_drop) //Fix for putting item arm objects into others' inventory
			source.show_text("You can't put \the [item] on [target] when it's attached to you!", "red")
			interrupt(INTERRUPT_ALWAYS)
			return
		logTheThing(LOG_COMBAT, source, "tries to put \an [item] on [constructTarget(target,"combat")] at at [log_loc(target)].")
		icon = item.icon
		icon_state = item.icon_state
		for(var/mob/O in AIviewers(owner))
			O.show_message("<span class='alert'><B>[source] tries to put [item] on [target]!</B></span>", 1)
	else
		var/obj/item/I = target.get_slot(slot)
		if(!I)
			boutput(source, "<span class='alert'>There's nothing in that slot.</span>")
			interrupt(INTERRUPT_ALWAYS)
			return
		if(!isturf(target.loc))
			boutput(source, "<span class='alert'>You can't remove [I] from [target] when [(he_or_she(target))] is in [target.loc]!</span>")
			interrupt(INTERRUPT_ALWAYS)
			return
		logTheThing(LOG_COMBAT, source, "tries to remove \an [I] from [constructTarget(target,"combat")] at [log_loc(target)].")
		var/name = "something"
		if (!hidden)
			icon = I.icon
			icon_state = I.icon_state
			name = I.name

		for(var/mob/O in AIviewers(owner))
			O.show_message("<span class='alert'><B>[source] tries to remove [name] from [target]!</B></span>", 1)

	..() // we call our parents here because we need to set our icon and icon_state before calling them

/datum/action/bar/icon/otherItem/onEnd()
	..()

	if(BOUNDS_DIST(source, target) > 0 || target == null || source == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	var/obj/item/I = target.get_slot(slot)

	if(item)
		if(item == source.equipped() && !I)
			if(target.can_equip(item, slot))
				logTheThing(LOG_COMBAT, source, "successfully puts \an [item] on [constructTarget(target,"combat")] at at [log_loc(target)].")
				for(var/mob/O in AIviewers(owner))
					O.show_message("<span class='alert'><B>[source] puts [item] on [target]!</B></span>", 1)
				source.u_equip(item)
				if(QDELETED(item))
					return
				target.force_equip(item, slot)
				target.update_inv()
	else if (I) //Wire: Fix for Cannot execute null.handle other remove().
		if(I.handle_other_remove(source, target))
			logTheThing(LOG_COMBAT, source, "successfully removes \an [I] from [constructTarget(target,"combat")] at [log_loc(target)].")
			for(var/mob/O in AIviewers(owner))
				O.show_message("<span class='alert'><B>[source] removes [I] from [target]!</B></span>", 1)

			// Re-added (Convair880).
			if (istype(I, /obj/item/mousetrap/))
				var/obj/item/mousetrap/MT = I
				if (MT?.armed)
					for (var/mob/O in AIviewers(owner))
						O.show_message("<span class='alert'><B>...and triggers it accidentally!</B></span>", 1)
					MT.triggered(source, source.hand ? "l_hand" : "r_hand")
			else if (istype(I, /obj/item/mine))
				var/obj/item/mine/M = I
				if (M.armed && M.used_up != 1)
					for (var/mob/O in AIviewers(owner))
						O.show_message("<span class='alert'><B>...and triggers it accidentally!</B></span>", 1)
					M.triggered(source)

			target.u_equip(I)
			I.set_loc(target.loc)
			I.dropped(target)
			I.layer = initial(I.layer)
			I.add_fingerprint(source)
			target.update_inv()
		else
			boutput(source, "<span class='alert'>You fail to remove [I] from [target].</span>")

/datum/action/bar/icon/otherItem/onUpdate()
	..()
	if(BOUNDS_DIST(source, target) > 0 || target == null || source == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	if(item)
		if(item != source.equipped() || target.get_slot(slot))
			interrupt(INTERRUPT_ALWAYS)
	else
		if(!target.get_slot(slot=slot))
			interrupt(INTERRUPT_ALWAYS)
#undef STAM_COST

/// This is used when you try to set someones internals.
/datum/action/bar/icon/internalsOther
	duration = 40
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "internalsother"
	icon = 'icons/obj/clothing/item_masks.dmi'
	icon_state = "breath"
	var/mob/living/carbon/human/target
	var/remove_internals

/datum/action/bar/icon/internalsOther/New(Target)
	target = Target
	..()

/datum/action/bar/icon/internalsOther/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/internalsOther/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	for(var/mob/O in AIviewers(owner))
		if(target.internal)
			O.show_message("<span class='alert'><B>[owner] attempts to remove [target]'s internals!</B></span>", 1)
			remove_internals = 1
		else
			O.show_message("<span class='alert'><B>[owner] attempts to set [target]'s internals!</B></span>", 1)
			remove_internals = 0

/datum/action/bar/icon/internalsOther/onEnd()
	..()
	if(owner && target && BOUNDS_DIST(owner, target) == 0)
		if(remove_internals)
			target.internal.add_fingerprint(owner)
			for (var/obj/ability_button/tank_valve_toggle/T in target.internal.ability_buttons)
				T.icon_state = "airoff"
			target.internal = null
			target.update_inv()
			for(var/mob/O in AIviewers(owner))
				O.show_message("<span class='alert'><B>[owner] removes [target]'s internals!</B></span>", 1)
		else
			if (!istype(target.wear_mask, /obj/item/clothing/mask))
				interrupt(INTERRUPT_ALWAYS)
				return
			else
				if (istype(target.back, /obj/item/tank))
					target.internal = target.back
					target.update_inv()
					for (var/obj/ability_button/tank_valve_toggle/T in target.internal.ability_buttons)
						T.icon_state = "airon"
					for(var/mob/M in AIviewers(target, 1))
						M.show_message(text("[] is now running on internals.", src.target), 1)
					target.internal.add_fingerprint(owner)

/// This is used when you try to handcuff someone.
/datum/action/bar/icon/handcuffSet
	duration = 40
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "handcuffsset"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "handcuff"
	var/mob/living/carbon/human/target
	var/obj/item/handcuffs/cuffs

/datum/action/bar/icon/handcuffSet/New(Target, Cuffs)
	target = Target
	cuffs = Cuffs
	..()

/datum/action/bar/icon/handcuffSet/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null || cuffs == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	if(target.hasStatus("handcuffed"))
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/handcuffSet/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null || cuffs == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	logTheThing(LOG_COMBAT, owner, "attempts to handcuff [constructTarget(target,"combat")] with [cuffs] at [log_loc(owner)].")

	duration *= cuffs.apply_multiplier

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.traitHolder.hasTrait("training_security"))
			duration = round(duration / 2)

	for(var/mob/O in AIviewers(owner))
		O.show_message("<span class='alert'><B>[owner] attempts to handcuff [target]!</B></span>", 1)

/datum/action/bar/icon/handcuffSet/onEnd()
	..()
	var/mob/ownerMob = owner
	if(owner && ownerMob && target && cuffs && !target.hasStatus("handcuffed") && cuffs == ownerMob.equipped() && BOUNDS_DIST(owner, target) == 0)

		var/obj/item/handcuffs/tape/cuffs2

		if (initial(cuffs.amount) > 1)
			if (cuffs.amount >= 1)
				cuffs2 = new /obj/item/handcuffs/tape
				cuffs2.apply_multiplier = cuffs.apply_multiplier
				cuffs2.remove_self_multiplier = cuffs.remove_self_multiplier
				cuffs2.remove_other_multiplier = cuffs.remove_other_multiplier
				cuffs.amount--
				if (cuffs.amount < 1 && cuffs.delete_on_last_use)
					ownerMob.u_equip(cuffs)
					boutput(ownerMob, "<span class='alert'>You used up the remaining length of [istype(cuffs, /obj/item/handcuffs/tape_roll) ? "tape" : "ziptie"].</span>")
					qdel(cuffs)
				else
					boutput(ownerMob, "<span class='notice'>The [cuffs.name] now has [cuffs.amount] lengths of [istype(cuffs, /obj/item/handcuffs/tape_roll) ? "tape" : "ziptie"] left.</span>")
			else
				boutput(ownerMob, "<span class='alert'>There's nothing left in the [istype(cuffs, /obj/item/handcuffs/tape_roll) ? "tape roll" : "ziptie"].</span>")
				interrupt(INTERRUPT_ALWAYS)
		else
			ownerMob.u_equip(cuffs)

		logTheThing(LOG_COMBAT, ownerMob, "handcuffs [constructTarget(target,"combat")] with [cuffs2 ? "[cuffs2]" : "[cuffs]"] at [log_loc(ownerMob)].")

		if (cuffs2 && istype(cuffs2))
			cuffs2.set_loc(target)
			target.handcuffs = cuffs2
		else
			cuffs.set_loc(target)
			target.handcuffs = cuffs
		target.drop_from_slot(target.r_hand)
		target.drop_from_slot(target.l_hand)
		target.drop_juggle()
		target.setStatus("handcuffed", duration = INFINITE_STATUS)
		target.update_clothing()

		for(var/mob/O in AIviewers(ownerMob))
			O.show_message("<span class='alert'><B>[owner] handcuffs [target]!</B></span>", 1)

/// This is used when you try to remove someone elses handcuffs.
/datum/action/bar/icon/handcuffRemovalOther
	duration = 70
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "handcuffsother"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "handcuff"
	var/mob/living/carbon/human/target

/datum/action/bar/icon/handcuffRemovalOther/New(Target)
	target = Target
	..()

/datum/action/bar/icon/handcuffRemovalOther/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	if(!target.hasStatus("handcuffed"))
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/handcuffRemovalOther/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

	if(target != null && ishuman(target) && target.hasStatus("handcuffed"))
		var/mob/living/carbon/human/H = target
		duration = round(duration * H.handcuffs.remove_other_multiplier)

	if(ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if(H.traitHolder.hasTrait("training_security"))
			duration = round(duration / 2)

	for(var/mob/O in AIviewers(owner))
		O.show_message("<span class='alert'><B>[owner] attempts to remove [target]'s handcuffs!</B></span>", 1)

/datum/action/bar/icon/handcuffRemovalOther/onEnd()
	..()
	if(owner && target?.hasStatus("handcuffed"))
		var/mob/living/carbon/human/H = target
		H.handcuffs.drop_handcuffs(H)
		H.update_inv()
		for(var/mob/O in AIviewers(H))
			O.show_message("<span class='alert'><B>[owner] manages to remove [target]'s handcuffs!</B></span>", 1)

/// This is used when you try to resist out of handcuffs.
/datum/action/bar/private/icon/handcuffRemoval
	duration = 600
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "handcuffs"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "handcuff"

/datum/action/bar/private/icon/handcuffRemoval/New(dur)
	duration = dur
	..()

/datum/action/bar/private/icon/handcuffRemoval/onStart()
	..()
	if(owner != null && ishuman(owner) && owner.hasStatus("handcuffed"))
		var/mob/living/carbon/human/H = owner
		duration = round(duration * H.handcuffs.remove_self_multiplier)

	owner.visible_message("<span class='alert'><B>[owner] attempts to remove the handcuffs!</B></span>")

/datum/action/bar/private/icon/handcuffRemoval/onUpdate()
	. = ..()
	if(!owner.hasStatus("handcuffed"))
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/private/icon/handcuffRemoval/onInterrupt(flag)
	..()
	boutput(owner, "<span class='alert'>Your attempt to remove your handcuffs was interrupted!</span>")
	if(!(flag & INTERRUPT_ACTION))
		src.resumable = FALSE

/datum/action/bar/private/icon/handcuffRemoval/onEnd()
	..()
	if(owner != null && ishuman(owner) && owner.hasStatus("handcuffed"))
		var/mob/living/carbon/human/H = owner
		H.handcuffs.drop_handcuffs(H)
		H.visible_message("<span class='alert'><B>[H] attempts to remove the handcuffs!</B></span>")
		boutput(H, "<span class='notice'>You successfully remove your handcuffs.</span>")

/// Resisting out of shackles (Convair880).
/datum/action/bar/private/icon/shackles_removal
	duration = 450
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "shackles"
	icon = 'icons/obj/clothing/item_shoes.dmi'
	icon_state = "orange1"

/datum/action/bar/private/icon/shackles_removal/New(dur)
	duration = dur
	..()

/datum/action/bar/private/icon/shackles_removal/onStart()
	..()
	for(var/mob/O in AIviewers(owner))
		O.show_message(text("<span class='alert'><B>[] attempts to remove the shackles!</B></span>", owner), 1)

/datum/action/bar/private/icon/shackles_removal/onInterrupt(flag)
	..()
	boutput(owner, "<span class='alert'>Your attempt to remove the shackles was interrupted!</span>")

/datum/action/bar/private/icon/shackles_removal/onEnd()
	..()
	if (owner != null && ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if (H.shoes && H.shoes.chained)
			var/obj/item/clothing/shoes/SH = H.shoes
			H.u_equip(SH)
			SH.set_loc(H.loc)
			H.update_clothing()
			if (SH)
				SH.layer = initial(SH.layer)
			for(var/mob/O in AIviewers(H))
				O.show_message("<span class='alert'><B>[H] manages to remove the shackles!</B></span>", 1)
			H.show_text("You successfully remove the shackles.", "blue")


/datum/action/bar/private/welding
	duration = 2 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "welding"
	var/call_proc_on = null
	var/obj/effects/welding/E
	var/list/start_offset
	var/list/end_offset


	id = null
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	/// Set to the path of the proc that will be called if the action bar finishes.
	var/proc_path = null
	/// What the target of the action is, if any.
	var/target = null
	/// What string is broadcast once the action bar finishes.
	var/end_message = ""
	/// What is the maximum range target and owner can be apart? need to modify before starting the action.
	var/maximum_range = 1
	/// A list of args for the proc thats called once the action bar finishes, if needed.
	var/list/proc_args = null
	bar_on_owner = FALSE

/datum/action/bar/private/welding/New(owner, target, duration, proc_path, proc_args, end_message, start, stop, call_proc_on)
	..()
	src.owner = owner
	src.target = target
	place_to_put_bar = target

	if(duration)
		src.duration = duration
	src.proc_path = proc_path
	src.proc_args = proc_args
	src.end_message = end_message
	src.start_offset = start
	src.end_offset = stop
	if(call_proc_on)
		src.call_proc_on = call_proc_on

/datum/action/bar/private/welding/onStart()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)
	if(!E)
		if(ismovable(src.target))
			var/atom/movable/M = src.target
			E = new(M)
			M.vis_contents += E
		else
			E = new(src.target)
		E.pixel_x = start_offset[1]
		E.pixel_y = start_offset[2]
		animate(E, time=src.duration, pixel_x=end_offset[1], pixel_y=end_offset[2])

/datum/action/bar/private/welding/onDelete(flag)
	if(E)
		if(ismovable(src.target))
			var/atom/movable/M = src.target
			M.vis_contents -= E
		qdel(E)
	..()

/datum/action/bar/private/welding/onEnd()
	..()
	if (!src.owner)
		interrupt(INTERRUPT_ALWAYS)
	if (src.target && !IN_RANGE(src.owner, src.target, src.maximum_range))
		interrupt(INTERRUPT_ALWAYS)

	if (end_message)
		src.owner.visible_message("[src.end_message]")

	if (src.call_proc_on)
		INVOKE_ASYNC(arglist(list(src.call_proc_on, src.proc_path) + src.proc_args))
	else if (src.target)
		INVOKE_ASYNC(arglist(list(src.target, src.proc_path) + src.proc_args))
	else
		INVOKE_ASYNC(arglist(list(src.owner, src.proc_path) + src.proc_args))

	if(E)
		if(ismovable(src.target))
			var/atom/movable/M = src.target
			M.vis_contents -= E
		qdel(E)

//CLASSES & OBJS

/obj/actions //These objects are mostly used for the attached_objs var on mobs to attach progressbars to mobs.
	icon = 'icons/ui/actions.dmi'
	anchored = 1
	density = 0
	opacity = 0
	layer = 5
	name = ""
	desc = ""
	mouse_opacity = 0

/obj/actions/bar
	icon_state = "bar"
	layer = 101
	plane = PLANE_HUD + 1
	appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | TILE_BOUND
	var/image/img

/obj/actions/bar/New()
	..()
	img = image('icons/ui/actions.dmi',src,"bar",6)

/obj/actions/bar/set_icon_state(new_state)
	..()
	src.img.icon_state = new_state

/obj/actions/border
	layer = 100
	icon_state = "border"
	plane = PLANE_HUD + 1
	appearance_flags = PIXEL_SCALE | RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM | KEEP_APART | TILE_BOUND
	var/image/img

/obj/actions/border/New()
	..()
	img = image('icons/ui/actions.dmi',src,"border",5)

/obj/actions/border/set_icon_state(new_state)
	..()
	src.img.icon_state = new_state

/**
 * Use this to start the action
 * actions.start(new/datum/action/bar/private/icon/magPicker(item, picker), usr)
 */
/datum/action/bar/private/icon/magPicker
	duration = 30 //How long does this action take in ticks.
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "magpicker"
	icon = 'icons/obj/items/items.dmi' //In these two vars you can define an icon you want to have on your little progress bar.
	icon_state = "magtractor-small"

	/// This will contain the object we are trying to pick up.
	var/obj/item/target = null
	/// This is the magpicker.
	var/obj/item/magtractor/picker = null

/datum/action/bar/private/icon/magPicker/New(Target, Picker)
	target = Target
	picker = Picker
	..()

/// Check for special conditions that could interrupt the picking-up here.
/datum/action/bar/private/icon/magPicker/onUpdate()
	..()
	// If the thing is suddenly out of range, interrupt the action. Also interrupt if the user or the item disappears.
	if(BOUNDS_DIST(owner, target) > 0 || picker == null || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/private/icon/magPicker/onStart()
	..()
	// If the thing is out of range, interrupt the action. Also interrupt if the user or the item disappears.
	if(BOUNDS_DIST(owner, target) > 0 || picker == null || target == null || owner == null || picker.working)
		interrupt(INTERRUPT_ALWAYS)
		return
	else
		picker.working = 1
		playsound(picker.loc, 'sound/machines/whistlebeep.ogg', 50, 1)
		out(owner, "<span class='notice'>\The [picker.name] starts to pick up \the [target].</span>")
		if (picker.highpower && isghostdrone(owner))
			var/mob/living/silicon/ghostdrone/our_drone = owner
			if (!our_drone.cell) return
			var/hpm_cost = 25 * (target.w_class * 2 + 1)
			// Buff HPM by making it pick things up faster, at the expense of cell charge
			// only allow it if more than double that power remains to keep it from bottoming out
			if (our_drone.cell.charge >= hpm_cost * 2)
				duration /= 3
				our_drone.cell.use(hpm_cost)

/// They did something else while picking it up. I guess you dont have to do anything here unless you want to.
/datum/action/bar/private/icon/magPicker/onInterrupt(flag)
	..()
	picker.working = 0

/datum/action/bar/private/icon/magPicker/onEnd()
	..()
	//Shove the item into the picker here!!!
	if (ismob(target.loc))
		var/mob/M = target.loc
		M.u_equip(target)
	picker.pickupItem(target, owner)
	actions.start(new/datum/action/magPickerHold(picker, picker.highpower), owner)


/datum/action/magPickerHold
	duration = 30
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	id = "magpickerhold"

	var/obj/item/magtractor/picker = null //This is the magpicker.

/datum/action/magPickerHold/New(Picker, hpm)
	if (hpm)
		src.interrupt_flags &= ~INTERRUPT_MOVE
	picker = Picker
	picker.holdAction = src
	..()

/// Again, check here for special conditions that are not normally handled in here. You probably dont need to do anything.
/datum/action/magPickerHold/onUpdate()
	..()
	if(picker == null || owner == null) //Interrupt if the user or the magpicker disappears.
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/magPickerHold/onStart()
	..()
	state = ACTIONSTATE_INFINITE //We can hold it indefinitely unless we move.
	if(picker == null || owner == null) //Interrupt if the user or the magpicker dont exist.
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/magPickerHold/onEnd()
	..()
	if (picker)
		picker.dropItem()

/datum/action/magPickerHold/onInterrupt(flag)
	..()
	if (picker)
		picker.dropItem()


/// Used when butchering a player-controlled critter.
/datum/action/bar/icon/butcher_living_critter
	duration = 120
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	id = "butcherlivingcritter"
	var/mob/living/critter/target

/datum/action/bar/icon/butcher_living_critter/New(Target, dur = null)
	if(dur)
		duration = dur
	target = Target
	..()

/datum/action/bar/icon/butcher_living_critter/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/butcher_living_critter/onInterrupt()
	..()
	if (target?.butcherer == owner)
		target.butcherer = null

/datum/action/bar/icon/butcher_living_critter/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null || target.butcherer)
		interrupt(INTERRUPT_ALWAYS)
		return
	target.butcherer = owner
	for(var/mob/O in AIviewers(owner))
		O.show_message("<span class='alert'><B>[owner] begins to butcher [target].</B></span>", 1)

/datum/action/bar/icon/butcher_living_critter/onEnd()
	..()
	target?.butcherer = null
	if(owner && target)
		target.butcher(owner)
		for(var/mob/O in AIviewers(owner))
			O.show_message("<span class='alert'><B>[owner] butchers [target].[target.butcherable == 2 ? "<b>WHAT A MONSTER</b>" : null]</B></span>", 1)

/datum/action/bar/icon/rev_flash
	duration = 4 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	id = "rev_flash"
	icon = 'icons/ui/actions.dmi'
	icon_state = "rev_imp"
	var/mob/living/target
	var/obj/item/device/flash/revolution/flash

/datum/action/bar/icon/rev_flash/New(Flash, Target)
	flash = Flash
	target = Target
	..()

/datum/action/bar/icon/rev_flash/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/rev_flash/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/rev_flash/onEnd()
	..()
	if(owner && target)
		if (ishuman(target))
			var/mob/living/carbon/human/H = target
			var/obj/item/implant/counterrev/found_imp = (locate(/obj/item/implant/counterrev) in H.implant)
			if (found_imp)
				found_imp.on_remove(target)
				H.implant.Remove(found_imp)
				qdel(found_imp)

				playsound(target.loc, 'sound/impact_sounds/Crystal_Shatter_1.ogg', 50, 0.1, 0, 0.9)
				target.visible_message("<span class='notice'>The counter-revolutionary implant inside [target] shatters into one million pieces!</span>")

			flash.flash_mob(target, owner)

/datum/action/bar/icon/mop_thing
	duration = 30
	interrupt_flags = INTERRUPT_STUNNED
	id = "mop_thing"
	icon = 'icons/obj/janitor.dmi' //In these two vars you can define an icon you want to have on your little progress bar.
	icon_state = "mop"
	var/atom/target
	var/obj/item/mop/mop

/datum/action/bar/icon/mop_thing/New(Mop, Target)
	mop = Mop
	target = Target
	duration = istype(target,/obj/fluid) ? 0 : 10
	..()

/datum/action/bar/icon/mop_thing/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/mop_thing/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/mop_thing/onEnd()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return
	if(owner && target)
		mop.clean(target, owner)

/datum/action/bar/icon/CPR
	duration = 4 SECONDS
	id = "cpr"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	icon = 'icons/ui/actions.dmi'
	icon_state = "cpr"
	var/mob/living/target

/datum/action/bar/icon/CPR/New(target)
	..()
	src.target = target

/datum/action/bar/icon/CPR/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || target.health > 0 || !src.can_cpr())
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/CPR/onStart()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || target.health > 0 || !src.can_cpr())
		interrupt(INTERRUPT_ALWAYS)
		return

	owner.visible_message("<span class='notice'><B>[owner] is trying to perform CPR on [target]!</B></span>")
	..()

/datum/action/bar/icon/CPR/onEnd()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || target.health > 0)
		..()
		interrupt(INTERRUPT_ALWAYS)
		return

	target.take_oxygen_deprivation(-15)
	target.losebreath = 0
	target.changeStatus("paralysis", -2 SECONDS)

	if(target.find_ailment_by_type(/datum/ailment/malady/flatline) && target.health > -50)
		if ((target.reagents?.has_reagent("epinephrine") || target.reagents?.has_reagent("atropine")) ? prob(5) : prob(2))
			target.cure_disease_by_path(/datum/ailment/malady/flatline)

	owner.visible_message("<span class='notice'>[owner] performs CPR on [target]!</span>")
	src.onRestart()

/datum/action/bar/icon/CPR/proc/can_cpr()
	if (ishuman(owner))
		var/mob/living/carbon/human/human_owner = owner
		if (human_owner.head && (human_owner.head.c_flags & COVERSMOUTH))
			boutput(human_owner, "<span class='alert'>You need to take off your headgear before you can give CPR!</span>")
			return FALSE

		if (human_owner.wear_mask)
			boutput(human_owner, "<span class='alert'>You need to take off your facemask before you can give CPR!</span>")
			return FALSE

	if (ishuman(target))
		var/mob/living/carbon/human/human_target = target
		if (human_target.head && (human_target.head.c_flags & COVERSMOUTH))
			boutput(owner, "<span class='alert'>You need to take off [human_target]'s headgear before you can give CPR!</span>")
			return FALSE

		if (human_target.wear_mask)
			boutput(owner, "<span class='alert'>You need to take off [human_target]'s facemask before you can give CPR!</span>")
			return FALSE

	if (isdead(target))
		owner.visible_message("<span class='alert'><B>[owner] tries to perform CPR, but it's too late for [target]!</B></span>")
		return FALSE

	return TRUE

/datum/action/bar/icon/forcefeed
	duration = 3 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	var/mob/mob_owner
	var/mob/consumer
	var/obj/item/reagent_containers/food/snacks/food
	var/obj/item/reagent_containers/food/drinks/drink

/datum/action/bar/icon/forcefeed/New(mob/consumer, item, icon, icon_state)
	..()
	src.consumer = consumer
	if (istype(item, /obj/item/reagent_containers/food/snacks))
		src.food = item
	else if (istype(item, /obj/item/reagent_containers/food/drinks/))
		src.drink = item
	else
		logTheThing(LOG_DEBUG, src, "/datum/action/bar/icon/forcefeed called with invalid food/drink type [item].")
	src.icon = icon
	src.icon_state = icon_state


/datum/action/bar/icon/forcefeed/onStart()
	if (!ismob(owner))
		interrupt(INTERRUPT_ALWAYS)
		return

	src.mob_owner = owner

	if(BOUNDS_DIST(owner, consumer) > 0 || !consumer || !owner || (mob_owner.equipped() != food && mob_owner.equipped() != drink))
		interrupt(INTERRUPT_ALWAYS)
		return
	..()

/datum/action/bar/icon/forcefeed/onUpdate()
	..()
	if(BOUNDS_DIST(owner, consumer) > 0 || !consumer || !owner || (mob_owner.equipped() != food && mob_owner.equipped() != drink))
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/forcefeed/onEnd()
	..()
	if(BOUNDS_DIST(owner, consumer) > 0 || !consumer || !owner || (mob_owner.equipped() != food && mob_owner.equipped() != drink))
		interrupt(INTERRUPT_ALWAYS)
		return
	if (!isnull(food))
		food.take_a_bite(consumer, mob_owner)
	else
		drink.take_a_drink(consumer, mob_owner)

/datum/action/bar/icon/syringe
	duration = 3 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	var/mob/mob_owner
	var/mob/target
	var/syringe_mode
	var/obj/item/reagent_containers/syringe/S

/datum/action/bar/icon/syringe/New(mob/target, item, icon, icon_state)
	..()
	src.target = target
	if (istype(item, /obj/item/reagent_containers/syringe))
		S = item
	else
		logTheThing(LOG_DEBUG, src, "/datum/action/bar/icon/syringe called with invalid type [item].")
	src.icon = icon
	src.icon_state = icon_state


/datum/action/bar/icon/syringe/onStart()
	if (!ismob(owner))
		interrupt(INTERRUPT_ALWAYS)
		return

	src.mob_owner = owner
	syringe_mode = S.mode

	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != S)
		interrupt(INTERRUPT_ALWAYS)
		return
	..()

/datum/action/bar/icon/syringe/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != S || syringe_mode != S.mode)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/syringe/onEnd()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != S || syringe_mode != S.mode)
		interrupt(INTERRUPT_ALWAYS)
		return
	if (!isnull(S) && syringe_mode == S.mode)
		S.syringe_action(owner, target)

/datum/action/bar/icon/pill
	duration = 3 SECONDS
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED | INTERRUPT_ATTACKED
	var/mob/mob_owner
	var/mob/target
	var/obj/item/reagent_containers/pill/P

/datum/action/bar/icon/pill/New(mob/target, item, icon, icon_state)
	..()
	src.target = target
	if (istype(item, /obj/item/reagent_containers/pill))
		P = item
		duration = round(clamp(P.reagents.total_volume, 30, 90) / 3 + 20)
	else
		logTheThing(LOG_DEBUG, src, "/datum/action/bar/icon/pill called with invalid type [item].")
	src.icon = icon
	src.icon_state = icon_state


/datum/action/bar/icon/pill/onStart()
	if (!ismob(owner))
		interrupt(INTERRUPT_ALWAYS)
		return

	src.mob_owner = owner

	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != P)
		interrupt(INTERRUPT_ALWAYS)
		return
	..()

/datum/action/bar/icon/pill/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != P)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/pill/onEnd()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || !target || !owner || mob_owner.equipped() != P)
		interrupt(INTERRUPT_ALWAYS)
		return
	if (!isnull(P))
		P.pill_action(owner, target)


/// Used when a spy tries to steal a large object.
/datum/action/bar/private/spy_steal
	duration = 30
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	id = "spy_steal"
	var/atom/target
	var/obj/item/uplink/integrated/pda/spy/uplink

/datum/action/bar/private/spy_steal/New(Target, Uplink)
	target = Target
	uplink = Uplink
	..()

/datum/action/bar/private/spy_steal/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/private/spy_steal/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return
	playsound(owner.loc, 'sound/machines/click.ogg', 60, 1)

/datum/action/bar/private/spy_steal/onEnd()
	..()
	if(owner && target && uplink)
		uplink.try_deliver(target, owner)



//DEBUG STUFF

/datum/action/bar/private/bombtest
	duration = 100
	id = "bombtest"

/datum/action/bar/private/bombtest/onEnd()
	..()
	qdel(owner)

/obj/bombtest
	name = "large cartoon bomb"
	desc = "It looks like it's gonna blow."
	icon = 'icons/obj/items/weapons.dmi'
	icon_state = "dumb_bomb"
	density = 1

/obj/bombtest/New()
	actions.start(new/datum/action/bar/private/bombtest(), src)
	..()

/// Constant rolling.
/datum/action/fire_roll
	duration = -1
	interrupt_flags = INTERRUPT_STUNNED
	id = "fire_roll"

	var/mob/living/M = 0

	var/sfx_interval = 5
	var/sfx_count = 0

	var/pixely = 0
	var/up = 1

/datum/action/fire_roll/New()
	..()

/datum/action/fire_roll/onUpdate()
	..()
	if (M?.hasStatus("resting") && !M.stat && M.getStatusDuration("burning"))
		M.update_burning(-1.5)

		M.set_dir(turn(M.dir,up ? -90 : 90))
		pixely += up ? 1 : -1
		if (pixely != clamp(pixely, -5,5))
			up = !up
		M.pixel_y = pixely

		sfx_count += 1
		if (sfx_count >= sfx_interval)
			playsound(M.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, 0 , 0.7)
			sfx_count = 0

		var/turf/T = get_turf(M)
		if (T.active_liquid)
			T.active_liquid.Crossed(M)

	else
		interrupt(INTERRUPT_ALWAYS)


/datum/action/fire_roll/onStart()
	..()
	M = owner
	if (!M.hasStatus("resting"))
		M.setStatus("resting", INFINITE_STATUS)
		var/mob/living/carbon/human/H = M
		if (istype(H))
			H.hud.update_resting()
		for (var/mob/O in AIviewers(M))
			O.show_message("<span class='alert'><B>[M] throws themselves onto the floor!</B></span>", 1, group = "resist")
	else
		for (var/mob/O in AIviewers(M))
			O.show_message("<span class='alert'><B>[M] rolls around on the floor, trying to extinguish the flames.</B></span>", 1, group = "resist")
	M.update_burning(-1.5)

	M.unlock_medal("Through the fire and flames", 1)
	playsound(M.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, 0 , 0.7)

/datum/action/fire_roll/onInterrupt(flag)
	..()
	if (M)
		M.pixel_y = 0

/datum/action/fire_roll/onEnd()
	..()
	if (M)
		M.pixel_y = 0


/// Delayed pickup, used for mousedrags to prevent 'auto clicky' exploits but allot us to pickup with mousedrag as a possibel action.
/datum/action/bar/private/icon/pickup
	duration = 0
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	id = "pickup"
	var/obj/item/target
	icon = 'icons/ui/actions.dmi'
	icon_state = "pickup"
	icon_plane = PLANE_HUD+2

/datum/action/bar/private/icon/pickup/New(Target)
	target = Target
	..()

/datum/action/bar/private/icon/pickup/onUpdate()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/private/icon/pickup/onStart()
	..()
	if(BOUNDS_DIST(owner, target) > 0 || target == null || owner == null)
		interrupt(INTERRUPT_ALWAYS)
		return
	if(ishuman(owner)) //This is horrible and clunky and probably going to kill us all, I am so, so sorry.
		var/mob/living/carbon/human/H = owner
		if(H.limbs?.l_arm && !H.limbs.l_arm.can_hold_items)
			interrupt(INTERRUPT_ALWAYS)
			return
		if(H.limbs?.r_arm && !H.limbs.r_arm.can_hold_items)
			interrupt(INTERRUPT_ALWAYS)
			return

/datum/action/bar/private/icon/pickup/onEnd()
	..()
	target.pick_up_by(owner)


/datum/action/bar/private/icon/pickup/then_hud_click
		var/atom/over_object
		var/params

/datum/action/bar/private/icon/pickup/then_hud_click/New(Target, Over, Parameters)
	target = Target
	over_object = Over
	params = Parameters
	..()

/datum/action/bar/private/icon/pickup/then_hud_click/onEnd()
	..()
	target.try_equip_to_inventory_object(owner, over_object, params)

/datum/action/bar/private/icon/pickup/then_obj_click
		var/atom/over_object
		var/params

/datum/action/bar/private/icon/pickup/then_obj_click/New(Target, Over, Parameters)
	target = Target
	over_object = Over
	params = Parameters
	..()

/datum/action/bar/private/icon/pickup/then_obj_click/onEnd()
	..()
	if (can_reach(owner,over_object) && ismob(owner) && owner:equipped() == target)
		usr = owner
		over_object.Attackby(target, owner, params)

/// General purpose action to anchor or unanchor stuff.
/datum/action/bar/icon/anchor_or_unanchor
	id = "table_tool_interact"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	duration = 5 SECONDS
	icon = 'icons/ui/actions.dmi'
	icon_state = "working"

	var/obj/target
	var/obj/item/tool
	var/unanchor = FALSE

/datum/action/bar/icon/anchor_or_unanchor/New(obj/target, obj/item/tool, unanchor=null, duration=null)
	..()
	if (target)
		src.target = target
	if (tool)
		src.tool = tool
		icon = src.tool.icon
		icon_state = src.tool.icon_state
	if (!isnull(unanchor))
		src.unanchor = unanchor
	else
		src.unanchor = target.anchored
	if (duration)
		src.duration = duration
	if (ishuman(owner))
		var/mob/living/carbon/human/H = owner
		if (H.traitHolder.hasTrait("carpenter") || H.traitHolder.hasTrait("training_engineer"))
			duration = round(duration / 2)

/datum/action/bar/icon/anchor_or_unanchor/onUpdate()
	..()
	if (target == null || tool == null || owner == null || BOUNDS_DIST(owner, target) > 0)
		interrupt(INTERRUPT_ALWAYS)
		return
	var/mob/source = owner
	if (istype(source) && tool != source.equipped())
		interrupt(INTERRUPT_ALWAYS)
		return
	if(unanchor && !target.anchored || !unanchor && target.anchored)
		interrupt(INTERRUPT_ALWAYS)
		return

/datum/action/bar/icon/anchor_or_unanchor/onStart()
	..()
	if(iswrenchingtool(tool))
		playsound(target, 'sound/items/Ratchet.ogg', 50, 1)
	else if(isweldingtool(tool))
		playsound(target, 'sound/items/Welder.ogg', 50, 1)
	else if(isscrewingtool(tool))
		playsound(target, 'sound/items/Screwdriver.ogg', 50, 1)
	owner.visible_message("<span class='notice'>[owner] begins [unanchor ? "un" : ""]anchoring [target].</span>")

/datum/action/bar/icon/anchor_or_unanchor/onEnd()
	..()
	owner.visible_message("<span class='notice'>[owner]  [unanchor ? "un" : ""]anchors [target].</span>")
	if(unanchor)
		target.anchored = FALSE
	else
		target.anchored = TRUE
