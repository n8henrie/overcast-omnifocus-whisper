#!/usr/bin/osascript -l JavaScript

'use strict'

const omnifocus = Application("OmniFocus")
const app = Application.currentApplication()
app.includeStandardAdditions = true

function run(argv) {
	let transcribeScript = argv[0]
	let code = `(() => {
		const re = new RegExp("^https://overcast\.fm");
		return (
			flattenedTasks
				.filter(task => re.test(task.note) && !task.completed)

				// Can only return primitive types, no Objects
				.map(task => [task.id.primaryKey, task.note])
		)
	})()`

  var results = omnifocus.evaluateJavascript(code)

	results.forEach(arr => {
		let note = arr[1]

		let reUrl = new RegExp("^https://overcast\.fm\\S*");
		let url = note.match(reUrl)[0]

		let reTime = new RegExp("/([0-9]{1,2}):([0-9]{1,2})$")
		let timeMatches = url.match(reTime)

		let task = {id: arr[0], url: url}

		let transcript = app.doShellScript(`${transcribeScript} "${task.id}" "${task.url}"`)

		let newNote
		if (timeMatches !== null) {
			let time = timeMatches[0].replace(/^\//, "")
			let seconds = parseInt(timeMatches[1]) * 60 + parseInt(timeMatches[2])
			newNote = `Transcribed from ${url} on ${new Date}\n`
			newNote += `timestamped at ${time} = ${seconds} seconds\n\n${transcript}`
		} else {
			newNote = `Transcribed from ${url} on ${new Date}\n\n${transcript}`
		}

		setNote(omnifocus, task.id, newNote)
	})
  return
}

function setNote(omnifocus, id, text) {
	let code = `(() => {
		Task.byIdentifier("${id}").note = \`${text}\`
	})()`
  return omnifocus.evaluateJavascript(code)
}
