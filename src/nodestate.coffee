EventEmitter2 = require('eventemitter2').EventEmitter2

class NodeState
	constructor: (@config) ->
		@_notifier = new EventEmitter2 {
			wildcard: true
		}
		@config.initial_state or= (state_name for state_name of @config.states)[0]
		@current_state_name = @config.initial_state
		@current_state = @config.states[@current_state_name]
		@current_data = config.initial_data or {}
		@_current_timeout = null

		@config.transitions or= []
		@config.autostart or= false

		#setup default events
		for state_name, events of @config.states
			@config.states[state_name]['Enter'] or= (data) ->
				@current_data = data

		@goto = (state_name, data) =>
			@current_data = data or @current_data
			previous_state_name = @current_state_name

			clearTimeout @_current_timeout if @_current_timeout
			for event_name, callback of @current_state
				console.log "removing listener for event: #{event_name}"
				@_notifier.removeListener event_name, callback

			#enter the new state
			@current_state_name = state_name
			@current_state = @config.states[@current_state_name]

			#register events for active state
			for event_name, callback of @current_state
				console.log "registering listener for event: #{event_name}"
				@_notifier.on event_name, callback

			transitions = []
			for transition in @config.transitions when ((transition[0] is previous_state_name or transition[0] is '*') and (transition[1] is @current_state_name or transition[1] is '*'))
				transitions.push transition

			if transitions.length
				doTransition = (transition, data, remaining, isDone) =>
					transition[2] data, remaining, (new_data, remaining) =>
						if remaining.length
							doTransition remaining[0], new_data, remaining, isDone
						else
							isDone(data)
			
				doTransition transitions[0], @current_data, transitions.slice(1), (data) =>
					@_notifier.emit 'Enter', @current_data
			else
				@_notifier.emit 'Enter', @current_data
		if @config.autostart
			@goto @current_state_name
	raise: (event_name, data) =>
		@_notifier.emit event_name, data
	wait: (milliseconds) =>
		@_current_timeout = setTimeout ( =>
			@_notifier.emit 'WaitTimeout', milliseconds, @current_data
		), milliseconds
	start: (data) =>
		@current_data or= data
		@goto @current_state_name
	stop: =>
		@_notifier.removeAllListeners()

module.exports = NodeState
										 
	
				
							





	
				
		
			
		
	
		
