
/// Controls the particle system
/datum/controller/process/particles
	var/datum/particleMaster/master

/datum/controller/process/particles/setup()
	name = "Particles"
	schedule_interval = 1 SECOND

	// putting this in a var so main loop varedit can get into the particleMaster
	master = particleMaster

/datum/controller/process/particles/copyStateFrom(datum/controller/process/target)
	var/datum/controller/process/particles/old_particles = target
	src.master = old_particles.master

/datum/controller/process/particles/doWork()
	// TODO roll the "loop" code from particleMaster back into this system
	master.Tick()

/// regular timing doesn't really apply since particles abuse the shit out of spawn and sleep
/datum/controller/process/particles/tickDetail()
	boutput(usr, "<b>Particles:</b>types: [master.particleTypes.len], systems: [master.particleSystems.len]<br>")
