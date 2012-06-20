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
						expect(goto_called).toBeTruthy()
						asyncSpecDone()
						fsm.stop()
				B: {}

		fsm = new TestState
			autostart: true
			initial_state: 'A'
		asyncSpecWait()

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

	it 'should cancel the wait timer when transitioning to another state', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@wait 50
						@goto 'B'
					WaitTimeout: (duration, data) ->
						@goto 'C'
				B:
					WaitTimeout: (duration, data) ->
						@goto 'D'
				C: {}
				D: {}

		fsm = new TestState()
		waits 60
		fsm.start()
		runs ->
			expect(fsm.current_state_name).toEqual('B')
			fsm.stop()

	it 'should cancel the wait timer when unwait is called', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@wait 50
						@raise 'CancelTimer'
					CancelTimer: (data) ->
						@unwait()
					WaitTimeout: (duration, data) ->
						@goto 'B'
				B: {}

		fsm = new TestState()
		waits 60
		fsm.start()
		runs ->
			expect(fsm.current_state_name).toEqual('A')
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
			initial_data: 1

		fsm.start()
		fsm.raise 'Data'
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
				B:
					Enter: (data) ->
						expect(fsm.current_state_name).toEqual('B')
						expect(fsm.current_data).toEqual(1)
						fsm.stop()
						asyncSpecDone()

		fsm = new TestState
			initial_state: 'A'
			initial_data: 1

		fsm.start()
		fsm.raise 'Data'
		asyncSpecWait()


	it 'should call the transition from A to B', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('AB')
						fsm.stop()
						asyncSpecDone()

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'

		fsm = new TestState()
		fsm.start()
		asyncSpecWait()

	it 'should call the transition from * to B', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('*B')
						fsm.stop()
						asyncSpecDone()

			transitions:
				'*':
					B: (data, callback) ->
						callback '*B'

		fsm = new TestState()
		fsm.start()
		asyncSpecWait()

	it 'should call the transition from A to *', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('A*')
						fsm.stop()
						asyncSpecDone()
			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'

		fsm = new TestState()

		fsm.start()

	it 'should call the transition from * to *', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('**')
						fsm.stop()
						asyncSpecDone()
			transitions:
				'*':
					'*': (data, callback) ->
						callback '**'

		fsm = new TestState()

		fsm.start()
		asyncSpecWait()

	it 'should ensure the transition from A to B should take precedence over * to B', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('AB')
						fsm.stop()
						asyncSpecDone()

			transitions:
				A:
					B: (data, callback) ->
						callback 'AB'
				'*':
					B: (data, callback) ->
						callback '*B'

		fsm = new TestState()
		fsm.start()
		asyncSpecWait()

	it 'should ensure the transition from * to B should take precedence over A to *', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('*B')
						fsm.stop()
						asyncSpecDone()

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'B': (data, callback) ->
						callback '*B'

		fsm = new TestState()

		fsm.start()
		asyncSpecWait()

	it 'should ensure the transition from A to * should take precedence over * to *', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B:
					Enter: (data) ->
						expect(fsm.current_data).toEqual('A*')
						fsm.stop()
						asyncSpecDone()

			transitions:
				A:
					'*': (data, callback) ->
						callback 'A*'
				'*':
					'*': (data, callback) ->
						callback '**'

		fsm = new TestState()

		fsm.start()
		asyncSpecWait()

	it 'should transition to state C', ->
		class TestState extends NodeState
			states:
				A:
					Enter: (data) ->
						@goto 'B'
				B: {}
				C:
					Enter: (data) ->
						expect(fsm.current_state_name).toEqual('C')
						fsm.stop()
						asyncSpecDone()
			transitions:
				A:
					B: (data, callback) ->
						@goto 'C'

		fsm = new TestState()

		fsm.start()
		asyncSpecWait()

	describe 'handling of 2 state machines simultaneously', ->
		it 'preserves local variables in state events', ->
			lastLocal = null
			class TestState extends NodeState
				constructor: (@local) ->
					super autostart: yes

				states:
					A:
						StoreLastLocal: ->
							lastLocal = @local

			ts1 = new TestState(1)
			ts2 = new TestState(2)

			setTimeout(
				->
					ts1.raise 'StoreLastLocal'
					expect(lastLocal).toEqual 1

					ts2.raise 'StoreLastLocal'
					expect(lastLocal).toEqual 2

					asyncSpecDone()
				200
			)
			asyncSpecWait()

		it 'preserves local variables in transitions', ->
			lastLocal = null
			class TestState extends NodeState
				constructor: (@local) ->
					super autostart: yes

				states:
					A: {}
					B: {}

				transitions:
					A:
						B: ->
							lastLocal = @local


			ts1 = new TestState(1)
			ts2 = new TestState(2)

			seriesWithTimeout = (tasks) ->
				run = (idx) ->
					return if idx is tasks.length
					tasks[idx]()
					setTimeout (-> run(idx+1)), 200
				run(0)

			seriesWithTimeout [
				-> ts1.goto 'B'
				-> expect(lastLocal).toEqual 1
				-> ts2.goto 'B'
				-> expect(lastLocal).toEqual 2
				-> asyncSpecDone()
			]

			asyncSpecWait()
