NodeState = require '../lib/nodestate'
 
describe 'NodeState', ->
	
	it 'should have a current state of A', ->
		class TestState extends NodeState
			states:
				A: {}
				B: {}
				C: {}

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_state_name).toEqual('A')
		fsm.stop()
	
	it 'should have a current state of B', ->
		class TestState extends NodeState
			states:
				A: {}
				B: {}
				C: {}

		fsm = new TestState
			intitial_state: 'B'

		fsm.start()
		expect(fsm.current_state_name).toEqual('A')
		fsm.stop()

	it 'should not call goto when autostart is false', ->
		goto_called = false

		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						goto_called = true
				B: {}
				C: {}

		fsm = new TestState
			autostart: false
			initial_state: 'A'

		expect(goto_called).toBeFalsy()
		fsm.stop()
	
	it 'should call goto when autostart is true', ->
		goto_called = false

		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						goto_called = true
				B: {}

		fsm = new TestState
			autostart: true
			initial_state: 'A'

		waits 50
		expect(goto_called).toBeTruthy()
		fsm.stop()
	
	it 'should transition from A to B after 50 milliseconds', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@wait 50, data
					WaitTimeout: (millis, data) ->
						@goto 'B'
				B: {}

		fsm = new TestState
			initial_state: 'A'

		fsm.start()
		expect(fsm.current_state_name).toEqual('A')
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			fsm.stop()
	
	it 'should transition from A to B after receiving data event', ->
		class TestState extends NodeState
			states:
				A:
					Data: (data) ->
						@goto 'B', data
				B: 
					Start: (data) ->

		fsm = new TestState
			initial_state: 'A'

		fsm.start()
		fsm.raise 'Data', 1
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			expect(fsm.current_data).toEqual(1)
			fsm.stop()
			
	it 'should retain current_data when goto is called with 1 argument', ->
		class TestState extends NodeState
			states:
				A:
					Data: (data) ->
						@goto 'B'
				B: {}

		fsm = new TestState
			initial_state: 'A'
			initial_data: 1

		fsm.start()
		fsm.raise 'Data'
		#give ourselves some room
		waits 60
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			expect(fsm.current_data).toEqual(1)
			fsm.stop()
	
	it 'should call the transition from A to B', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('AB')
		fsm.stop()
	
	it 'should call the transition from * to B', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				'*':
					B: (data, callback) ->
						callback '*B'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('*B')
		fsm.stop()
	
	it 'should call the transition from A to *', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('A*')
		fsm.stop()

	it 'should call the transition from * to *', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				'*':
					'*': (data, callback) ->
						callback '**'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('**')
		fsm.stop()

	it 'should ensure the transition from A to B should take precedence over * to B', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'
				'*':
					B: (data, callback) ->
						callback '*B'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('AB')
		fsm.stop()

	it 'should ensure the transition from * to B should take precedence over A to *', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'B': (data, callback) ->
						callback '*B'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('*B')
		fsm.stop()
	
	it 'should ensure the transition from A to * should take precedence over * to *', ->
		class TestState extends NodeState
			states:
				A: 
					Enter: (data) ->
						@goto 'B'
				B: 
					Enter: (data) ->

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'*': (data, callback) ->
						callback '**'

		fsm = new TestState()

		fsm.start()
		expect(fsm.current_data).toEqual('A*')
		fsm.stop()