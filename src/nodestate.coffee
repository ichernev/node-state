EventEmitter2 = require('eventemitter2').EventEmitter2

class NodeState
	constructor: (@config = {}) ->
		@_notifier = new EventEmitter2 { wildcard: true }

		#supply the proper context of 'this' to events
		states = {}
		for state, events of @states
			states[state] = {}
			for event, fn of events
				states[state][event] = fn.bind @
		@states = states

		#supply the proper context of 'this' to transitions
		transitions = {}
		for from_state, to_states of @transitions
			transitions[from_state] = {}
			for to, fn of to_states
				transitions[from_state][to] = fn.bind @
		@transitions = transitions

		@config.initial_state or= (state_name for state_name of @states)[0]
		@current_state_name = @config.initial_state
		@current_state = @states[@current_state_name]
		@current_data = @config.initial_data or {}
		@_current_timeout = null

		@config.autostart or= false

		#setup default events
		for state_name, events of @states
			@states[state_name]['Enter'] or= (data) ->
				@current_data = data
		if @config.autostart
			@goto @current_state_name

	goto: (state_name, data) =>
		@current_data = data or @current_data
		previous_state_name = @current_state_name

		clearTimeout @_current_timeout if @_current_timeout
		for event_name, callback of @current_state
			@_notifier.removeListener event_name, callback

		#enter the new state
		@current_state_name = state_name
		@current_state = @states[@current_state_name]

		#register events for active state
		for event_name, callback of @current_state
			@_notifier.on event_name, callback

		callback = (data) =>
			@current_data = data
			@_notifier.emit 'Enter', @current_data

		transition = (data, cb) =>
			cb data

		if @transitions[previous_state_name] and @transitions[previous_state_name][state_name]
			transition = @transitions[previous_state_name][state_name]
		else if @transitions['*'] and @transitions['*'][state_name]
			transition = @transitions['*'][state_name]
		else if @transitions[previous_state_name] and @transitions[previous_state_name]['*']
			transition = @transitions[previous_state_name]['*']
		else if @transitions['*'] and @transitions['*']['*']
			transition = @transitions['*']['*']

		process.nextTick =>
			transition @current_data, callback

	states: {}
	transitions: {}
	raise: (event_name, data) =>
		@_notifier.emit event_name, data
	wait: (milliseconds) =>
		@_current_timeout = setTimeout ( =>
			@_notifier.emit 'WaitTimeout', milliseconds, @current_data
		), milliseconds
	unwait: =>
		if @_current_timeout then clearTimeout @_current_timeout
	start: (data) =>
		@current_data or= data
		@goto @current_state_name
	stop: =>
		@_notifier.removeAllListeners()

module.exports = NodeState
