NodeState = require '../lib/nodestate'
 
describe 'NodeState', ->
	
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
		fsm = new NodeState
			autostart: false
			initial_state: 'A'
			states:
				A:
					Enter: (data) ->
						goto_called = true
				B: {}
				C: {}

		expect(goto_called).toBeFalsy()
		fsm.stop()
	
	it 'should call goto when autostart is true', ->
		goto_called = false
		fsm = new NodeState
			autostart: true
			initial_state: 'A'
			states:
				A: 
					Enter: (data) ->
						goto_called = true
				B: {}
		waits 50
		expect(goto_called).toBeTruthy()
		fsm.stop()
	
	it 'should transition from A to B after 50 milliseconds', ->
		fsm = new NodeState
			initial_state: 'A'
			states:
				A:
					Enter: (data) ->
						fsm.wait 50, data
					WaitTimeout: (millis, data) ->
						fsm.goto 'B'
				B: {}

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
				B: 
					Start: (data) ->

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
	
	it 'should call the transition from A to B', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'
		fsm.start()
		expect(fsm.current_data).toEqual('AB')
	
	it 'should call the transition from * to B', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				'*':
					B: (data, callback) ->
						callback '*B'
		fsm.start()
		expect(fsm.current_data).toEqual('*B')
	
	it 'should call the transition from A to *', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
		fsm.start()
		expect(fsm.current_data).toEqual('A*')

	it 'should call the transition from * to *', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				'*':
					'*': (data, callback) ->
						callback '**'
		fsm.start()
		expect(fsm.current_data).toEqual('**')

	it 'the transition from A to B should take precedence over * to B', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'
				'*':
					B: (data, callback) ->
						callback '*B'
		fsm.start()
		expect(fsm.current_data).toEqual('AB')

	it 'the transition from * to B should take precedence over A to *', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'B': (data, callback) ->
						callback '*B'
		fsm.start()
		expect(fsm.current_data).toEqual('*B')

	it 'the transition from A to * should take precedence over * to *', ->
		fsm = new NodeState
			states:
				A: 
					Enter: (data) ->
						fsm.goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'*': (data, callback) ->
						callback '**'
		fsm.start()
		expect(fsm.current_data).toEqual('A*')