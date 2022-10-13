
/// handles EXPLOSIONS
/datum/controller/process/explosions
	var/datum/explosion_controller/explosion_controller

/datum/controller/process/explosions/setup()
	name = "Explosions"
	schedule_interval = 0.5 SECONDS

	explosion_controller = explosions

/datum/controller/process/explosions/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/explosions/old_explosions = target
	src.explosion_controller = old_explosions.explosion_controller

/datum/controller/process/explosions/doWork()
	explosion_controller.process() //somehow runtimes null.process(), why the fuck is explosion controller gone???
