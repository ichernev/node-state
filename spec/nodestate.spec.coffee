NodeState = require '../lib/nodestate'
 
describe 'NodeState', ->
	
	it 'should create pre-, post-, and on- transitions for each state', ->
		config =
			states:
				A: {}
				B: {}
				C: {}
		fsm = new NodeState config

		expect(config.transitions).toNotBe(null)

		for state_name of config.states
			for prefix in ['post', 'pre', 'on']
				expect(config.transitions["#{prefix}#{state_name}"]).toNotBe(null)
				expect(config.transitions["#{prefix}#{state_name}"] instanceof Function).toBeTruthy()

		fsm.stop()

	it 'should have a current state of A', ->
		config =
			states:
				A: {}
				B: {}
				C: {}

		fsm = new NodeState config
		expect(fsm.current_state_name).toEqual('A')
		fsm.stop()
	
	it 'should have a current state of B', ->
		config =
			intitial_state: 'B'
			states:
				A: {}
				B: {}
				C: {}

		fsm = new NodeState config
		expect(fsm.current_state_name).toEqual('A')
		fsm.stop()

	it 'should not call goto when autostart is false', ->
		goto_called = false
		config =
			autostart: false
			initial_state: 'A'
			states:
				A: {}
				B: {}
				C: {}
			transitions:
				onA: (data, callback) ->
					goto_called = true
					callback data

		fsm = new NodeState config
		expect(goto_called).toBeFalsy()
		fsm.stop()

	it 'should call goto when autostart is true', ->
		goto_called = false
		config =
			autostart: true
			initial_state: 'A'
			states:
				A: {}
				B: {}
			transitions:
				onA: (data, callback) ->
					goto_called = true
					callback data
		fsm = new NodeState config
		expect(goto_called).toBeTruthy()
		fsm.stop()
	
	it 'should transition from A to B after 50 milliseconds', ->
		fsm = new NodeState
			initial_state: 'A'
			states:
				A:
					WaitTimeout: (millis, data) ->
						fsm.goto 'B'
				B: {}
			transitions:
				onA: (data, callback) ->
					fsm.wait 50
					callback data

		fsm.start()
		expect(fsm.current_state_name).toEqual('A')
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			fsm.stop()
	
	it 'should transition from A to B after receiving data event', ->
		fsm = new NodeState
			initial_state: 'A'
			states:
				A:
					Data: (data) ->
						fsm.goto 'B', data
				B: {}

		fsm.start()
		fsm.raise 'Data', 1
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			expect(fsm.current_data).toEqual(1)
			fsm.stop()
			
	it 'should retain current_data when goto is called with 1 argument', ->
		fsm = new NodeState
			initial_state: 'A'
			initial_data: 1
			states:
				A:
					Data: (data) ->
						fsm.goto 'B'
				B: {}

		fsm.start()
		fsm.raise 'Data'
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			expect(fsm.current_data).toEqual(1)
			fsm.stop()
	
