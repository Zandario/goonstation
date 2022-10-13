
/// Handles rebuilding of camnets if needed
/datum/controller/process/camnets

/datum/controller/process/camnets/setup()
	name = "Camera Networks"
	schedule_interval = 3 SECONDS

/datum/controller/process/camnets/doWork()
	rebuild_camera_network() //Will only actually do something if it needs to.
