# Node-State: A finite state machine (FSM) implementation for Node.js and CoffeeScript

Node-State is intended as a rough port of the Akka FSM module available for Scala.  While other FSM implementation exist for Node, none seemed to offer the flexibility and the clear DSL offered by Akka.  This project is an attempt at bringing that to the Node/CoffeeScript world.

## installation

	npm install node-state

## concepts

Node-State has three main concepts: States, Events, and Transitions.  At any one time, a state-machine will be in one of several pre-defined states.  Each state has one or more events that it will listen for and respond to until transitioning to the next state.  Transitions are special events that occur in between moving from one state to the next.  Transitions can be used to set-up initial data for a new state, intercept a transition and redirect to another state, or handle loic that may not necessarily belong in a specific state.

## defining a new state-machine

State machines use CoffeeScript's class and inheritance system, and should inherit from NodeState.  While it is certainly possible to implement this inheritance using plain javascript, that is beyond the scope of this documentation, and is not recommended.

### adding states
```javascript
class MyStateMachine extends NodeState
	states:
```
