/*
	Pipes. That move fluids. Probably.
	By Firebarrage
*/

/obj/fluid_pipe
	name = "fluid pipe"
	desc = "A pipe. For fluids."
	icon = 'icons/obj/disposal.dmi'
	anchored = ANCHORED
	density = 0
	var/pipe_shape = ""
	var/capacity = DEFAULT_FLUID_CAPACITY
	var/used_capacity = 0
	var/pipe_type = FLUIDPIPE_NORMAL
	var/list/obj/fluid_pipe/edges = list()
	var/visited = 0 // Used by DFS when creating networks
	var/datum/flow_network/network = null // Which network is mine?

/obj/fluid_pipe/New()
	START_TRACKING
	..()

/obj/fluid_pipe/disposing()
	STOP_TRACKING
	..()

// NOTE: Don't call this during construction. The other pipes might not be there yet.
// This needs to be called during network generation
/obj/fluid_pipe/proc/populate_edges()
	edges = list()
	DEBUG_MESSAGE("Populating edges of pipe [log_loc(src)].")
	DEBUG_MESSAGE("This is a [pipe_type] facing [dir].")
	switch(pipe_shape)
		if("straight")
			// welcome to a way-too-long switch statement
			// I might compress this. I might not. Leave me alone.
			// TODO: Compress this... Please.
			switch(src.dir)
				if(NORTH,SOUTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
				if(EAST, WEST)
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
		if("Y")
			switch(src.dir)
				if(NORTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
				if(SOUTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
				if(EAST)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
				if(WEST)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
		if("elbow")
			switch(src.dir)
				if(NORTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
				if(SOUTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
				if(EAST)
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
				if(WEST)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
		if("source","sink")
			switch(src.dir)
				if(NORTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y + 1, src.z))
						edges.Add(pipe)
						break
				if(SOUTH)
					for(var/obj/fluid_pipe/pipe in locate(src.x, src.y - 1, src.z))
						edges.Add(pipe)
						break
				if(EAST)
					for(var/obj/fluid_pipe/pipe in locate(src.x + 1, src.y, src.z))
						edges.Add(pipe)
						break
				if(WEST)
					for(var/obj/fluid_pipe/pipe in locate(src.x - 1, src.y, src.z))
						edges.Add(pipe)
						break
	DEBUG_MESSAGE("[edges.len] adjacent nodes found.")

/obj/fluid_pipe/straight
	icon_state = "pipe-s"
	pipe_shape = "straight"
/obj/fluid_pipe/t_junction
	icon_state = "pipe-y" // Ignore the arrow for now
	pipe_shape = "Y"

/obj/fluid_pipe/elbow
	icon_state = "pipe-c"
	pipe_shape = "elbow"
/obj/fluid_pipe/source
	icon_state = "pipe-t"
	pipe_shape = "source"
	pipe_type = FLUIDPIPE_SOURCE

/obj/fluid_pipe/sink
	icon_state = "pipe-t"
	pipe_shape = "sink"
	pipe_type = FLUIDPIPE_SINK



/proc/make_fluid_networks()
	DEBUG_MESSAGE("Setting up fluid pipe networks.")

	// Populate all edges
	// TODO in future: We dont need to do this every time we remake the fluid networks, only update the moved pipes.
	for_by_tcl(node, /obj/fluid_pipe)
		node.populate_edges()

	var/obj/fluid_pipe/root = find_unvisited_node()
	if(!root)
		DEBUG_MESSAGE("No fluid pipes detected.")
		return
	do
		DEBUG_MESSAGE("Creating fluid network. Root node is at [log_loc(root)].")
		new /datum/flow_network(root)
		root = find_unvisited_node()
	while(root)

/proc/find_unvisited_node()
	for_by_tcl(pipe, /obj/fluid_pipe)
		if(!pipe.network)
			return pipe
	return null


// Represents a single connected set of fluid pipes
/datum/flow_network
	var/list/obj/fluid_pipe/nodes = list()
	var/list/obj/fluid_pipe/sources = list()
	var/list/obj/fluid_pipe/sinks = list()
	var/datum/reagents/fp_holder/pipe_cont = new /datum/reagents/fp_holder()
	#define REACTOR 1
	#define TURBINE 2
	var/last = 0

/datum/flow_network/New(obj/fluid_pipe/root)
	..()
	pipe_cont.net = src
	START_TRACKING
	DEBUG_MESSAGE("Constructing fluid pipe network")
	nodes = DFS(root)
	for(var/obj/fluid_pipe/N as anything in nodes)
		N.network = src
		if(N.pipe_type == FLUIDPIPE_SINK)
			sinks.Add(N)
		else if(N.pipe_type == FLUIDPIPE_SOURCE)
			sources.Add(N)
	ford_fulkerson(src)


	// Remove for full release
	DEBUG_MESSAGE("Fluid network created. Listing structure.")
	for(var/obj/fluid_pipe/node in nodes)
		var/edges = "([node.loc.x], [node.loc.y]): \["
		for(var/obj/fluid_pipe/adj in node.edges)
			edges += "([adj.loc.x], [adj.loc.y]), "
		edges += "\]"
		DEBUG_MESSAGE(edges)

/datum/flow_network/disposing()
	STOP_TRACKING
	..()

/datum/flow_network/proc/clear_DFS_flags()
	for(var/obj/fluid_pipe/FN as anything in nodes)
		FN.visited = FALSE


// Look at me! I paid attention in my algorithms class!
// Warning: For efficiency flow is pre-calculated based on an assumption
// that the full capacity is used every tick. This may not actually be the case.
// So there are some weird cases where you could theoretically turn off one source
// and allow a second source to increase its intake but this wont allow that to happen
// The only solution to this is recalculating flows every tick but we're not going to do that.
/proc/ford_fulkerson(datum/flow_network/FN)
	var/list/obj/fluid_pipe/path = list()
	FN.clear_DFS_flags()
	path = find_augmenting_path(FN)
	DEBUG_MESSAGE("Augmenting path: [print_pipe_list(path)]")
	while(length(path))
		flow_through(path, DEFAULT_FLUID_CAPACITY / FN.sources.len)
		path = find_augmenting_path(FN)
		DEBUG_MESSAGE("Augmenting path: [print_pipe_list(path)]")

/proc/find_augmenting_path(datum/flow_network/FN)
	// Try to find one from each source
	var/list/obj/fluid_pipe/stack = list()
	for(var/obj/fluid_pipe/source in FN.sources)
		FN.clear_DFS_flags()
		find_source_sink_path(source,stack)
		if(length(stack) > 0)
			return stack
	return null

/proc/find_source_sink_path(obj/fluid_pipe/source, list/obj/fluid_pipe/stack)
	// Push self
	stack.Add(source)
	if(source.pipe_type == FLUIDPIPE_SINK)
		return
	DEBUG_MESSAGE("Pushing pipe [showCoords(source.x,source.y,source.z)]")
	source.visited = 1
	for(var/obj/fluid_pipe/adj in source.edges)
		if(adj.visited || adj.used_capacity == adj.capacity)
			continue
		find_source_sink_path(adj,stack)
		// Did the DFS succeed?
		if(stack[stack.len].pipe_type == FLUIDPIPE_SINK)
			return // We did it!
	//Well shit. Dead end.
	stack.Remove(source)
	DEBUG_MESSAGE("Popping pipe [showCoords(source.x,source.y,source.z)]")
	return


/proc/print_pipe_list(var/obj/fluid_pipe/pipes)
	. = "\["
	for(var/obj/fluid_pipe/pipe in pipes)
		. += "[showCoords(pipe.x,pipe.y,pipe.z)], "
	. += "]"


/proc/flow_through(list/obj/fluid_pipe/path, max_allowed_flow)
	var/min_capacity = path[1].capacity - path[1].used_capacity
	// How much can we send?
	for(var/obj/fluid_pipe/pipe as anything in path)
		if(pipe.capacity - pipe.used_capacity < min_capacity)
			min_capacity = pipe.capacity - pipe.used_capacity
	min_capacity = clamp(min_capacity, 0, max_allowed_flow)
	DEBUG_MESSAGE("Pushing [min_capacity] through this path.")
	for(var/obj/fluid_pipe/pipe in path)
		pipe.used_capacity += min_capacity
	return


/proc/DFS(obj/fluid_pipe/root)
	root.visited = TRUE
	var/list/obj/fluid_pipe/nodes = list()
	nodes.Add(root)
	if(!root.edges)
		return
	for(var/obj/fluid_pipe/adj as anything in root.edges)
		if(!adj.visited)
			adj.visited = TRUE
			nodes += DFS(adj)
	return nodes

// Its like the normal DFS but its loud. As in it yells pipe locations at you. For testing.
// AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
proc/DFS_LOUD(obj/fluid_pipe/root)
	DEBUG_MESSAGE("DFS Start - Arrived at node [showCoords(root.x,root.y,root.z)]")
	var/listret = "\["
	for(var/i = 1; i <= root.edges.len; i++)
		listret += "([root.edges[i].x],[root.edges[i].y],[root.edges[i].z]) "
	listret += "]"
	DEBUG_MESSAGE("Adjacent nodes: [listret]")
	root.visited = TRUE
	var/list/obj/fluid_pipe/nodes = list()
	nodes.Add(root)
	if(!root.edges)
		return
	for(var/obj/fluid_pipe/adj as anything in root.edges)
		if(!adj.visited)
			adj.visited = TRUE
			nodes += DFS(adj)
	listret = "\["
	for(var/i = 1; i <= nodes.len; i++)
		listret += "([nodes[i].x],[nodes[i].y],[nodes[i].z]) "
	listret += "]"
	DEBUG_MESSAGE("DFS end - returning [listret].")
	return nodes


/datum/reagents/fp_holder
	var/datum/flow_network/net

/datum/reagents/fp_holder/New()
	..()
