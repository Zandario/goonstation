/chui/window
	/**
	 * The windows name is what is displayed in the titlebar.
	 * It does not need to be unique, and is just a utility.
	 */
	var/name = "Untitled Window"

	/**
	 * This is a list of people that have the window currently open.
	 * It is preferable you use verify first.
	 */
	var/list/client/subscribers = new


	/// This is a list of people currently in the process of subscribing to the window. It should clear itself out.
	var/list/client/connecting = new
	/// How many times can we retry the client validation?
	var/max_retries = 5
	/// What is the base time we should wait between tries?
	var/time_per_try = 2

	/**
	 * This is the desired theme. Make sure it is set to a text string.
	 * It is automatically changed to the datum type in New()
	 */
	var/chui/theme/theme = "base"

	/**
	 * This is the atom the window is attached to. Can be set in New()
	 * If set, Chui will use it to determine whether or not the viewer
	 * is both in range and is fully conscious to be using the window and
	 * for receiving updates.
	 */
	var/atom/theAtom

	/**
	 * This is the active template. The template engine is currently incomplete.
	 * However, you can set this to a text string (or file; it'll load the file into the var
	 * required) to have the panel's body set to it when necessary. Preferable to automatic
	 * generation as to not pollute the string table.
	 */
	var/chui/template/template = null

	/**
	 * A list of sections. Will eventually work by being an associative list of templates.
	 * You will be able to call .SetSection( name ) or set the section via code.
	 * It will allow you to split up your window into multiple HTML files/code.
	 */
	var/list/sections = list() //Section system, is a TODO.

	/// This var can be overridden in order to explicitly define the size of a newly opened window
	var/windowSize = null

	//The list of Chui flags. Not currently used to its full potential.
	//CHUI_FLAG_SIZABLE  -> Allows the window to be resized.
	//CHUI_FLAG_MOVABLE  -> Allows the window to be moved.
	//CHUI_FLAG_CLOSABLE -> Allows the window to be closed.
	var/flags = CHUI_FLAG_SIZABLE | CHUI_FLAG_MOVABLE | CHUI_FLAG_CLOSABLE

	/// A list of template vars
	var/list/templateVars = new

/// If overriden, be sure to call ..()
/chui/window/New(atom/adam)
	..()
	if(!chui) chui = new()
	theme = chui.GetTheme(theme)
	theAtom = adam

/**
 * Override this if you have a DM defined window.
 * Returns the HTML the window will have.
 */
/chui/window/proc/GetBody()
	if(template)
		if(isfile(template))
			template = file2text(template)
			return template
		else if(istext(template))
			return template
		return template.Generate()
	return "Untemplated Window."

/**
 * Do not call directly.
 * Called to generate HTML for a client and desired body text.
 */
/chui/window/proc/generate(client/victim, body)
	var/list/params = list("js" = list(), "css" = list(), "title" = src.name, data = list( "ref" = "\ref[src]", "flags" = flags))//todo, better this.
	return theme.generateHeader(params) + theme.generateBody(body, params) + theme.generateFooter()

/**
 * Subscribe a client to use this window.
 * Chui will open the window on their client and have its content set appropriately.
 * The window ref is the \ref[src] of the window.
 */
/chui/window/proc/Subscribe(client/who)
	if (isnull(who))
		return FALSE
	CDBG1( "[who] subscribed to [name]" )
	if(!IsSubscribed(who) && !(who in connecting))

		connecting += who //Add who to list of clients currently attempting to subscribe
		//theme.streamToClient( who )
		who << browse( src.generate(who, src.GetBody()), "window=\ref[src];titlebar=0;can_close=0;can_resize=0;can_scroll=0;border=0[windowSize ?";size=[windowSize]": null]" )

		var/extrasleep = 0
		var/retries = max_retries
		/*
		The clientside instance of chui will call back through the "registered" topic call.
		This will then take the client out of the connecting list, move them into the subscribed list and break the loop below.
		*/
		do
			if(winexists(who, "\ref[src].browser")) //Fuck if I know
				winset( who, "\ref[src]", "on-close \".chui-close \ref[src]\"" )

			if (who in connecting)
				sleep(time_per_try + extrasleep++)
			else
				break

		while (retries-- > 0) //Keep trying to send the UI update until it times out or they get it.

		if (who in connecting)
			connecting -= who
			who << browse(null, "window=\ref[src]")


/**
 * Returns true if the client is subscribed.
 * Will also perform a validation check and unsubscribe those who don't pass it.
 * Use of this is preferable to using the subscribers var; but is appropriately slower.
 */
/chui/window/proc/IsSubscribed(client/whom)
	var/actuallySubbed = (whom in subscribers)
	if (actuallySubbed && Validate(whom))
		return TRUE
	else if (actuallySubbed)
		Unsubscribe(whom)
	return FALSE


/**
 * Unsubscribes a client from the window.
 * Will also close the window.
 */
/chui/window/proc/Unsubscribe(client/who)
	CDBG1("[who] unsubscribed to [name]")
	subscribers -= who
	who << browse(null, "window=\ref[src]")


/// See /client/proc/Browse instead.
/chui/window/proc/bbrowse(client/who, body, options, forceChui)
	var/list/config = params2list(options)

	if(!forceChui && !who.use_chui && !config["override_setting"])	//"override_setting=1"
		// hello, yes, this is evil. but it works. feel free to replace with something non-evil that works. --pali
		// Zamu here - using this as a good time to inject "make most nonchui popups suck less ass" code.
		// This is still really gross, but I'm still working on improving that.
		if (body)
			body = {"<!doctype html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<style type='text/css'>
		body {
			font-family: Tahoma, Arial, sans-serif;
			font-size: [(who.preferences && who.preferences.font_size) ? "[who.preferences.font_size]%" : "10pt"];
			}
		pre, tt, code {
			font-family: Consolas, 'Lucidia Console', monospace;
			}
	</style>
	<script>
		// Keeps the scroll position of a window when it reloads / updates.
		// Not really ideal in cases where the window changes contents, but better than nothing.
		function updateScroll() {window.name = document.documentElement.scrollTop || document.body.scrollTop;}
		window.addEventListener("beforeunload", updateScroll);
		window.addEventListener("scroll", updateScroll);
		window.addEventListener("load", function() {document.documentElement.scrollTop = document.body.scrollTop = window.name;});
	</script>
</head>
<body>
"} + body
		who << browse(body,"titlebar=1;can_close=1;can_resize=1;can_scroll=1;border=0;[options]")
		return

	var/name = config[ "window" ]
	if (isnull(body))
		usr << browse(null, options)
		return
	if(!name)
		CRASH("No window name given")
	var/flags = CHUI_FLAG_MOVABLE
	if (isnull(config["can_resize"]) || text2num(config["can_resize"]))
		flags |= CHUI_FLAG_SIZABLE
	if (config["fade_in"] && text2num(config["fade_in"]))
		flags |= CHUI_FLAG_FADEIN
	if (isnull(config["can_close"]) || text2num(config["can_close"]))
		flags |= CHUI_FLAG_CLOSABLE
	var/title = config["title"]
	var/list/datah = list( "ref" = name, "flags" = flags )
	if(!title)
		datah["needstitle"] = 1

	// use_chui_custom_frames allows enabling the standard Windows UI,
	// which allows people an out if chui decides to go berzerk
	var/list/built = list("js" = list(), "css" = list(), "title" = (title || ""), data = datah)//todo, better this.
	who << browse(theme.generateHeader(built) + theme.generateBody(body, built) + theme.generateFooter(), who.use_chui_custom_frames ? "titlebar=0;can_close=0;can_resize=0;can_scroll=0;border=0;[options]" : "titlebar=1;can_close=1;can_resize=1;can_scroll=1;border=1;[options]")
	//winset( who, "\ref[src]", "on-close=\".chui-close \ref[src]\"" )
	//theme.streamToClient( who )

/**
 * Check if a client should actually be subscribed.
 * Can be used to check if someone is subscribed without unsubscribing them
 * if they don't check out.
 */
/chui/window/proc/Validate(client/cli)
	if(!cli)
		return FALSE
	//if( !victim.stat && !(panel.flags & chui_FLAG_USEDEAD) ) return -1
	if(!(cli in subscribers))
		//wow this is some jerk.. i blame spacenaba
		CDBG2("Validation failed for [cli] -- Not subscribed.")
		return FALSE
	if (winget(cli, "\ref[src]", "is-visible" ) == "false")
		CDBG2("Validation failed for [cli] -- Not visible.")
		return FALSE
	if (theAtom && (!isAI(cli.mob) && !issilicon(cli.mob)) && GET_DIST( cli.mob.loc, theAtom.loc ) > 2)
		CDBG2("Validation failed for [cli] -- Too far.")
		return FALSE
	return TRUE

/**
 * Calls a Javascript function with a set number of arguments on everyone subscribed.
 * For prediction, you can include a client to exclude from this.
 */
/chui/window/proc/CallJSFunction(fname, list/arguments, client/exclude)
	for(var/client/c in subscribers)
		if(!Validate(c))
			Unsubscribe(c)
	for(var/i = 1, i <= subscribers.len, i++)
		subscribers[i] << output("[list2params( arguments )]", "\ref[src].browser:[fname]")

/// Called when a template variable changes.
/chui/window/proc/OnVar(name, value, setFromDM)

/// Sets a template var and displays it.
/chui/window/proc/SetVar(name, value)
	templateVars[name] = value
	CallJSFunction("chui.templateSet", list(name, value))
	OnVar(name, value, 1)

/// Sets multiple template vars. Accepts associated list.
/chui/window/proc/SetVars(list/vars)
	var/list/toSend = list()
	for(var/k in vars)
		if(isnull(templateVars[k]) || templateVars[k] != vars[k])
			toSend[k] = vars[k]
			templateVars[k] = vars[k]
	if(toSend.len)
		CallJSFunction( "chui.templateBulk", list(json_encode(toSend)) )

/// Gets a template var.
/chui/window/proc/GetVar(name)
	return templateVars[name]

/// Generates a template var; use it for cases of inline HTML (instead of SetVar).
/chui/window/proc/template(name, value)
	if(!templateVars[name])
		templateVars[name] = value
	return "<span id='chui-tmpl-[name]'>[isnull(templateVars[ name ]) ? "please wait..." : templateVars[name]]</span>"

//UNUSED..
/*
/chui/window/proc/_transfer(largebodyoftext)
	if(1)
		CallJSFunction("chui.onReceive", list( largebodyoftext))
		return
	var/chunkCount = length(largebodyoftext) / CHUNK_SIZE
	var/id = ++src.xferID
	callJSFunction("chui._setupReceive", list("chunkcount" = chunkCount, "finalLength" = length(largebodyoftext), list("id" = id))
	for( var/i = 1, i <= chunkCount, i++ )
		callJSFunction("chui._chunk", list("id" = id, "chunk" = copytext(largebodyoftext, i * CHUNK_SIZE, (i+1) * CHUNK_SIZE)
	callJSFunction("chui._finishReceive", list("id" = id)
*/

/// Override this instead of Topic()
/chui/window/proc/OnTopic(client/clint, href, href_list[])

/// Called when a theme button is clicked. Includes which client did the deed and any other assorted gubbins.
/chui/window/proc/OnClick(client/who, id, href_list)


/// Called when Javascript sends a request; return with data to be given back to JS.
/chui/window/proc/OnRequest(method, list/data)
	return template.OnRequest(method, data)


/chui/window/Topic(href, href_list[])
	if(!IsSubscribed(usr.client) && !(usr.client in connecting))
		usr << browse(null, "window=\ref[src]")
		return
	var/action = href_list["_cact"]
	if(!isnull(action))
		if (action == "section" && !isnull(href_list["section"]) && (href_list["section"] in sections))
			if(!hascall(src, href_list["section"] + "Section"))
				boutput(src, "<span style='color: #f00'>Call 1-800 CODER.</span>")
				throw EXCEPTION("1-800 Coder: you allowed a section that doesn't exist!!! RAAHHHH")
			call(href_list["section"], src)(href_list)
		else if(action == "request")
			var/method = href_list["_path"]
			var/id = href_list["_id"]
			if(isnull(method) || isnull(id))
				world << "FATAL: Null ID/Method for BYREQ."
				return
			//TODO: When JSON is included. callJSFunction( "chui.reqReturn",
		else if(action == "click" && href_list["id"])
			OnClick(usr.client, href_list["id"], href_list["data"])
		else if(action == "register" ) //The client calls this automatically to let the server know it's ready to receive data.
			DEBUG_MESSAGE("Chui register action received from [usr]")
			var/client/C = usr.client
			if(C in connecting)
				DEBUG_MESSAGE("Finalizing [usr]'s subscription")
				connecting -= C
				subscribers |= C
		else
			OnTopic(usr.client, href, href_list) //umm
	else
		OnTopic(usr.client, href, href_list)


/// Called when the close button is clicked on both
/client/verb/chuiclose(window as text)
	set name = ".chui-close"
	set hidden = TRUE
	var/chui/window/win = locate( window )

	// istype(win) && win.Unsubscrbe(src)
	if(istype(win))
		win.Unsubscribe(src)
	else
		/// This exists to allow chui windows to work with the normal onclose.
		var/onCloseRef = winget(src, window, "on-close")
		/// Unfortunately this ends up calling it twice if a window is closed by chui.
		var/list/split = splittext(onCloseRef, " ")

		// If anyone has a better solution go for it but don't just remove it because it will break things.
		if(split.len >= 2)
			var/datum/targetDatum = locate(split[2])
			if (targetDatum)
				targetDatum.Topic("close=1", params2list("close=1"), targetDatum)

		// Might not be a standard chui window but we'll play along.
		src << browse( null, "window=[window]" )
		if(src?.mob)
			// boutput(world, "[src] was [src.mob.machine], setting to null")
			if (istype(win) && win.theAtom && isobj(win.theAtom))
				win.theAtom:remove_dialog(src.mob)
			else
				src.mob.remove_dialogs()

/**
 * A chui substitute for usr << browse()
 * Mostly the same syntax.
 */
/client/proc/Browse(html, opts, forceChui )
	chui.staticinst.bbrowse(src, html, opts, forceChui)

/mob/proc/Browse(html, opts, forceChui)
	if(src.client)
		chui.staticinst.bbrowse(src.client, html, opts, forceChui)
