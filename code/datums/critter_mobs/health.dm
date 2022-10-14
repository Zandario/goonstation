/datum/healthHolder
	var/name = "generic health"
	var/associated_damage_type = "none"
	var/overlay_icon = null
	var/list/threshold_values = list()
	var/list/threshold_icon_states = list()
	var/mob/living/holder = null
	var/image/damage_overlay
	/// The maximum amount of health this holder has.
	var/maximum_value = 100
	/// The current amount of health this holder has.
	var/value = 100
	/// Value at the last call of Life() - maintained automatically.
	var/last_value = 100
	/// The lowest amount of health this holder can represent.
	var/minimum_value = -INFINITY
	/// If the value reaches this threshold, on_deplete() is called.
	var/depletion_threshold = -INFINITY
	/// Currently displayed level of overlay, helps to check if update is needed.
	var/current_overlay = 0
	/// If true, damage overlay will be blood colored.
	var/assume_blood_color = 0
	var/damage_multiplier = 1
	/// If true, the mob's health will be increased by the value of this.
	/// And maximum health will be increased by the maximum value of this.
	/// The mob still dies at health = 0
	var/count_in_total = 1


/datum/healthHolder/New(mob/M)
	..()
	holder = M
	value = maximum_value

/datum/healthHolder/disposing()
	holder = null
	..()

/datum/healthHolder/proc/TakeDamage(amt, bypass_multiplier = 0)
	if (!bypass_multiplier && amt > 0)
		amt *= damage_multiplier
	if (minimum_value < maximum_value)
		value = clamp(value - amt, minimum_value, maximum_value)
	else
		value = min(value - amt, maximum_value)
	health_update_queue |= holder

/datum/healthHolder/proc/HealDamage(amt)
	TakeDamage(-amt)

/datum/healthHolder/proc/prevents_speech()
	return 0

/datum/healthHolder/proc/damaged()
	return value < maximum_value

/datum/healthHolder/proc/on_deplete()
	holder.death(FALSE)

/datum/healthHolder/proc/Life()
	if (value != last_value)
		update_overlay()
	on_life()
	last_value = value

/datum/healthHolder/proc/on_life()

/datum/healthHolder/proc/update_overlay()
	if (!overlay_icon || !threshold_icon_states.len || !length(threshold_values))
		return
	var/next_overlay = 0
	while (next_overlay < threshold_values.len && value < threshold_values[next_overlay + 1])
		next_overlay++
	if (next_overlay == current_overlay)
		return
	if (!damage_overlay && next_overlay != 0)
		damage_overlay = image(overlay_icon, threshold_icon_states[next_overlay])
		if (assume_blood_color && holder.blood_id)
			var/datum/reagent/R = reagents_cache[holder.blood_id]
			if (R)
				damage_overlay.color = rgb(R.fluid_r, R.fluid_g, R.fluid_b)
	else if (damage_overlay)
		holder.overlays -= damage_overlay
	if (next_overlay != 0)
		damage_overlay.icon_state = threshold_icon_states[next_overlay]
		holder.overlays += damage_overlay
	current_overlay = next_overlay

/datum/healthHolder/proc/on_react(datum/reagents/R, method = 1, react_volume = null)

/datum/healthHolder/proc/on_attack(obj/item/I, mob/M)
	return 1

/datum/healthHolder/proc/get_damage_assessment()
	if (maximum_value > 0)
		return "[name] health: [value]/[maximum_value]"
	else
		return "[name] damage: [maximum_value - value]"
