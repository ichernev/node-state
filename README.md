# Node-State: A finite state machine (FSM) implementation for Node.js and CoffeeScript

Node-State is intended as a rough port of the Akka FSM module available for Scala.  While other FSM implementation exist for Node, none seemed to offer the flexibility and the clear DSL offered by Akka.  This project is an attempt at bringing that to the Node/CoffeeScript world.

## installation

    npm install node-state

## concepts

Node-State has three main concepts: States, Events, and Transitions.  At any one time, a state-machine will be in one of several pre-defined states.  Each state has one or more events that it will listen for and respond to until transitioning to the next state.  Transitions are special events that occur in between moving from one state to the next.  Transitions can be used to set-up initial data for a new state, intercept a transition and redirect to another state, or handle loic that may not necessarily belong in a specific state.

## defining a new state-machine

State machines use CoffeeScript's class and inheritance system, and should inherit from NodeState.  While it is certainly possible to implement this inheritance using plain javascript, that is beyond the scope of this documentation, and is not recommended.

### adding states and events
```coffeescript
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
```coffeescript
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

1. Explicitly named 'from' and 'to' states, i.e. `A -> B`
2. Wildcard 'from' state and explicitly named 'to' state, i.e. `'*' -> B`
3. Explicitly named 'from' state and wildcard 'to' state, i.e. `A -> '*'`
4. Wildcard 'from' and 'to' states, i.e. `'*' -> '*'`

## configuring and running your state-machine
The NodeState constructor supports an optional configuration object, which supports 3 properties.

+ `autostart` - Defaults to `false`.  This parameter determines whether the state machine should automatically activate and enter the initial state, or if it should wait for the start() method to be called.
+ `initial_data` - Defaults to an empty object ( {} ).  Use this to specify any data that might be needed by the initial state.
+ `initial_state` - The name of the first state that the machine should enter.  By default, this will be the name of the first state defined in the states list.
+ `sync_goto` - when you issue `goto` the new state's Enter function is called syncrhonously, in the current run-loop iteration

```coffeescript
fsm = new MyStateMachine
  autostart: true
  initial_data: 'I can be data of any type, but default to {}'
  initial_state: 'B'
```

### available methods
Note that any of the following methods can be called from outside of the state machine by replacing `@` (the CoffeeScript shortcut for `this`) with a reference to the state machine. example:

```coffeescript
class MyStateMachine extends NodeState
  states:
    A:
      Enter: (data) ->
        @goto 'B', { key: 'new data'}
    B:
      Enter: (data) ->
        @goto 'C'

fsm = new MyStateMachine
fsm.start()
fsm.wait 300
fsm.stop()
```

+ `@goto(state_name, [data])` - Described previously, this signals the state machine to begin transitioning from the current state to state_name.  @goto takes an optional data argument to send new data to the next state.

+ `@raise(event_name, [data])` - Described previously, this raises an event with the name specified by event_name, and optionally passes new data to that event handler.  Note that @raise does not cause a change in state, and only the active state's event handlers can respond to the event that has been raised.

+ `@wait(timeout_milliseconds, [data])` - Sleeps for the specified timeout_milliseconds before raising the WaitTimeout event.  WaitTimeout's event handler is defined slightly differently than most, as it has an additional parameter for the timeout value.

```coffeescript
class MyStateMachine extends NodeState
  states:
    A:
      Enter: (data) ->
        @wait 300, { key: 'new data'}
      WaitTimeout: (timeout, data) ->
        console.log timeout
    B:
      Enter: (data) ->
        #do something
```

+ `@unwait` - Cancels the current wait operation.  Usually, the combination of @wait/@unwait is used if you are waiting a specified time period for other events to come in.  `@unwait` would be used once you've received an event of interest and no longer want to respond to the timer.

+ `@start` - Kicks off the transition to the initial state.
+ `@stop` - Unregisters all event handlers for the state machine, effectively turning it off.  In the future, pre- and post-stop event hooks may be added to allow for additional cleanup during shutdown.

## History
+ v1.4.3
  - fix bug in stop
+ v1.4.1
  - properly build js file, upgrade!
+ v1.4.0
  - added enable/disable methods
  - rewrote tests to use mocha/chai
+ v1.3.0
  - bugfixes and `sync_goto` option to constructor

## Credits
+ originally published by [Nick Fisher]("https://github.com/nrf110")
