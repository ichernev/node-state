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

		@config.transitions or= {}
		@config.autostart or= false

		#setup default transitions
		for state_name, events of @config.states
			for prefix in ['post', 'pre', 'on']
				@config.transitions["#{prefix}#{state_name}"] or= (data, callback) ->
					callback data

		@goto = (state_name, data) =>
			console.log "received #{data}"
			@current_data = data or @current_data
			console.log "current data #{@current_data}"
			#executes before moving away from the current state
			post_transition = @config.transitions["post#{@current_state_name}"]

			post_transition @current_data, (data = @current_data) =>
				@current_data = data
				clearTimeout @_current_timeout if @_current_timeout
				for event_name, callback of @current_state
					@_notifier.removeListener event_name, callback

				#executes before entering the new state
				pre_transition = @config.transitions["pre#{state_name}"]

				pre_transition @current_data, (data = @current_data) =>

					#enter the new state
					@current_data = data
					@current_state_name = state_name
					@current_state = @config.states[@current_state_name]

					#register events for active state
					for event_name, callback of @current_state
						@_notifier.on event_name, callback

					on_transition = @config.transitions["on#{state_name}"]
					on_transition @current_data, (data = @current_data) =>
						@current_data = data
		
		if @config.autostart
			@goto @current_state_name

	wait: (milliseconds) =>
		@_current_timeout = setTimeout ( =>
			@_notifier.emit 'WaitTimeout', milliseconds, @current_data
		), milliseconds
	raise: (event_name, data) =>
		@_notifier.emit event_name, data
	start: (data) =>
		@current_data or= data
		@goto @current_state_name
	stop: =>
		@_notifier.removeAllListeners()

module.exports = NodeState
										 
	
				
							





	
				
		
			
		
	
		
