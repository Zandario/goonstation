
/// handles timed player actions
/datum/controller/process/actions
	var/datum/controller/process/actions/action_controller

/datum/controller/process/actions/setup()
	name = "Actions"
	schedule_interval = 0.5 SECONDS

	action_controller = actions

/datum/controller/process/actions/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/actions/old_actions = target
	src.action_controller = old_actions.action_controller

/datum/controller/process/actions/doWork()
	action_controller.process()
