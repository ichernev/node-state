# Node-State: A finite state machine (FSM) implementation for Node.js and CoffeeScript

Node-State is intended as a rough port of the Akka FSM module available for Scala.  While other FSM implementation exist for Node, none seemed to offer the flexibility and the clear DSL offered by Akka.  This project is an attempt at bringing that to the Node/CoffeeScript world.

## installation

	npm install node-state

## concepts

Node-State has three main concepts: States, Events, and Transitions.  At any one time, a state-machine will be in one of several pre-defined states.  Each state has one or more events that it will listen for and respond to until transitioning to the next state.  Transitions are special events that occur in between moving from one state to the next.  Transitions can be used to set-up initial data for a new state, intercept a transition and redirect to another state, or handle loic that may not necessarily belong in a specific state.

## defining a new state-machine

State machines use CoffeeScript's class and inheritance system, and should inherit from NodeState.  While it is certainly possible to implement this inheritance using plain javascript, that is beyond the scope of this documentation, and is not recommended.

### adding states and events
```javascript
class MyStateMachine extends NodeState
	states:
		A:
			Enter: (data) ->
				@goto 'B', { key: 'new data'}
		B:
			Enter: (data) ->
				@raise 'MyCustomEvent', data
			MyCustomEvent: (data) ->
				#do something
```

In the example above, we've created a new state machine with 2 states: A and B.  The keys under each state are the names of events to which the state will respond.  All states by default will listen for an Enter event, which is called automatically upon entering the new state.  In the Enter event of state A, we see the @goto method.  @goto will unregister event listeners for state A, and enter state B.  The second argument to @goto is data to be passed to the next state.  Upon entering state B, we see the @raise method.  @raise raises an event which will be responded to by the current state, if an appropriate event has been registered.  Again, the second argument may be used to pass new data to the next event handler.  In both @raise and @goto, the second argument is optional.  Omitting it will pass along the data received by the current event handler.

### adding transitions
```javascript
class MyStateMachine extends NodeState
	states:
		A:
			Enter: (data) ->
				@goto 'B', { key: 'new data'}
		B:
			Enter: (data) ->
				@goto 'C'
		C:
			Enter:  (data) ->
				@goto 'D'
		D:
			Enter: (data) ->
				
	transitions:
		A:

			B: (data, callback) ->
				#do setup for new state

		'*':
			A: (data, callback) ->

			D: (data, callback) ->

			'*': (data, callback) ->

		C:

			'*': (data, callback) ->
```

Above, we have defined transitions from A -> B, * -> A, * -> D, * -> *, and C -> *.  The * is a wildcard, it means "any state".  There are a few important things to note about transitions. First, they are called in between states, that is after all event handlers have been unregistered from the previous state, but before registering new handlers and entering the next state.  Second, only the single most applicable transition will be called, not all matching transitions.  Order of precedence, from most to least important, is as follows:

1. Explicitly named 'from' and 'to' states, i.e. A -> B
2. Wildcard 'from' state and explicitly named 'to' state, i.e. '*' -> B
3. Explicitly named 'from' state and wildcard 'to' state, i.e. A -> '*'
4. Wildcard 'from' and 'to' states, i.e. '*' -> '*'

