EventEmitter = require('events').EventEmitter

class NodeState
  constructor: (@config = {}) ->
    @_notifier = new EventEmitter
    @disabled = false

    # supply the proper context of 'this' to events
    states = {}
    for state, events of @states
      states[state] = {}
      for event, fn of events
        states[state][event] = fn.bind @
    @states = states

    # supply the proper context of 'this' to transitions
    transitions = {}
    for from_state, to_states of @transitions
      transitions[from_state] = {}
      for to, fn of to_states
        transitions[from_state][to] = fn.bind @
    @transitions = transitions

    @current_state_name =
      @config.initial_state ?
      (state_name for state_name of @states)[0]
    @current_state = @states[@current_state_name]
    @current_data = @config.initial_data
    @_current_timeout = null

    @config.autostart ?= false
    @config.sync_goto ?= false

    if @config.autostart
      @goto @current_state_name

  goto: (state_name, data) ->
    return if @disabled

    @current_data = data ? @current_data
    previous_state_name = @current_state_name

    clearTimeout @_current_timeout if @_current_timeout
    for event_name, callback of @current_state
      @_notifier.removeListener event_name, callback

    # enter the new state
    @current_state_name = state_name
    @current_state = @states[@current_state_name]

    # register events for active state
    for event_name, callback of @current_state
      @_notifier.on event_name, callback

    callback = (data) =>
      @current_data = data
      @_notifier.emit 'Enter', @current_data

    transition =
      @transitions[previous_state_name]?[state_name] ?
      @transitions['*']?[state_name] ?
      @transitions[previous_state_name]?['*'] ?
      @transitions['*']?['*'] ?
      (data, cb) => cb data

    if @config.sync_goto
      transition @current_data, callback
    else
      process.nextTick =>
        transition @current_data, callback

  raise: (event_name, data) ->
    @_notifier.emit event_name, data

  wait: (milliseconds) ->
    @_current_timeout = setTimeout(
      => @_notifier.emit 'WaitTimeout', milliseconds, @current_data
      milliseconds
    )

  unwait: ->
    clearTimeout @_current_timeout if @_current_timeout

  start: (data) ->
    @current_data = data if data?
    @goto @current_state_name

  stop: ->
    @_notifier.removeAllListeners()
    @unwait()

  disable: ->
    return if @disabled
    @stop()
    @disabled = true

  enable: (state, data) ->
    return unless @disabled
    @disabled = false
    @goto state, data if state?

  wrapCb: (fn) ->
    (args...) =>
      return if @disabled
      fn args...

  states: {}
  transitions: {}

module.exports = NodeState
