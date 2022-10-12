/chui/template
	var/chui/window/winder

/chui/template/New(window)
	..()
	winder = window

/chui/template/proc/SetTemplate(code)
	throw EXCEPTION("Method stub: SetCode")

/chui/template/proc/CallAction(ref, type, client/cli)

/chui/template/proc/Generate()

/chui/template/proc/OnRequest(method, list/data)
	return null

/*
/bysql/value/function/chui
	var/chui/template/bysql/tmpl

/bysql/value/function/chui/New(chui/template/bysql/template)
	src.tmpl = template

/bysql/value/function/chui/proc/Call()
	//fart

/bysql/value/function/chui/Invoke(list/bysql/value/argz)

/bysql/value/function/chui/Call(arglist(argz)) //utility

/bysql/value/function/chui/addButton/Call(bysql/value/label, bysql/value/callback, bysql/value/data)
	if(!label || !callback || label.type != "TEXT" || callback.type != "FUNCTION")
		throw EXCEPTION("Expected TEXT, FUNCTION!")
	var/id = num2text(tmpl.id++)

	tmpl.rendered += tmpl.winder.theme.generateButton(id, label)
	tmpl.hook(id, callback, data)

/chui/template/bysql
	var/bysql/engine/template
	var/bysql/closure/closure
	var/id = 0

	var/list/hooks

/chui/template/bysql/proc/hook(id, bysql/value/function/func, bysql/value/data)
	hooks[id] = list(func, data)

	var/rendered = ""

/chui/template/bysql/New(var/chui/window/window)
	template = new
	template.LoadLibs( "chui", "chui", src )
	..()

/chui/template/bysql/SetTemplate(code)
	closure = template.LoadString(code)
*/
