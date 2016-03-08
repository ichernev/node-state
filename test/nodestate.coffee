NodeState = require '../src/nodestate'
should = require('chai').should()

describe 'NodeState', ->
  describe 'initial state', ->
    it 'uses first given state as initial state', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> done()
          B: Enter: -> done 'in B'

      new TestState().start()

    it 'honors initial_state over first given state', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> done 'in A'
          B: Enter: -> done()

      new TestState(initial_state: 'B').start()

  describe 'autostart', ->
    it 'does not enter initial state if autostart is false', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> done 'in A'

      new TestState autostart: no
      done()

    it 'does enter initial state if autostart is true', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> done()

      new TestState autostart: yes

  describe 'wait', ->
    it 'fires WaitTimeout event after calling wait', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: -> @wait 10
            WaitTimeout: -> done()

      new TestState autostart: yes

    it 'cancels the wait timer when transitioning to another state', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: (data) ->
              @wait 10
              @goto 'B'
            WaitTimeout: ->
              done 'wait timeout in A'
          B:
            Enter: ->
              # wait for the timeout in case it triggers
              setTimeout done, 10
            WaitTimeout: ->
              done 'wait timeout in B'

      new TestState autostart: yes

    it 'cancels the wait timer when unwait is called', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: (data) ->
              @wait 10
              @unwait()
              # wait for the timeout in case it triggers
              setTimeout done, 10
            WaitTimeout: (duration, data) ->
              done 'wait timeout triggered'

      new TestState autostart: yes

  describe 'goto', ->
    it 'enters specified state on goto', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> @goto 'B'
          B: Enter: -> done()

      new TestState autostart: yes

    it 'retains old data when goto is called with 1 argument', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal 'initial-data'
            done()

      new TestState autostart: yes, initial_data: 'initial-data'

    it 'use passed data when goto is called with 2 argument', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B', 'the-new-data'
          B: Enter: (data) ->
            data.should.equal 'the-new-data'
            done()

      new TestState autostart: yes, initial_data: 'the-old-data'

    it 'honors goto calls from transition callbacks', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> @goto 'B'
          B: {}
          C: Enter: -> done()

        transitions:
          A: B: (data, callback) -> @goto 'C'

      new TestState autostart: yes

  describe 'transition callbacks', ->
    it 'calls callback for A -> B when going from A to B', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal 'AB'
            done()

        transitions:
          A: B: (data, callback) ->
            callback 'AB'

      new TestState autostart: yes

    it 'calls callback for * -> B when going from A to B', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal '*B'
            done()

        transitions:
          '*': B: (data, callback) ->
            callback '*B'

      new TestState autostart: yes

    it 'calls callback for A -> * when going from A to B', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal 'A*'
            done()

        transitions:
          A: '*': (data, callback) ->
            callback 'A*'

      new TestState autostart: yes

    it 'calls callback for * -> * when going from A to B', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal '**'
            done()

        transitions:
          '*': '*': (data, callback) ->
            callback '**'

      new TestState autostart: yes

    describe 'precedence', ->
      it 'A -> B takes precedence over * -> B', (done) ->
        class TestState extends NodeState
          states:
            A: Enter: ->
              @goto 'B'
            B: Enter: (data) ->
              data.should.equal 'AB'
              done()

          transitions:
            A: B: (data, callback) ->
              callback 'AB'
            '*': B: (data, callback) ->
              callback '*B'

        new TestState autostart: yes

      it '* -> B takes precedence over A -> *', (done) ->
        class TestState extends NodeState
          states:
            A: Enter: ->
              @goto 'B'
            B: Enter: (data) ->
              data.should.equal '*B'
              done()

          transitions:
            A: '*': (data, callback) ->
              callback 'A*'
            '*': 'B': (data, callback) ->
              callback '*B'

        new TestState autostart: yes

      it 'A to * takes precedence over * -> *', (done) ->
        class TestState extends NodeState
          states:
            A: Enter: ->
              @goto 'B'
            B: Enter: (data) ->
              data.should.equal 'A*'
              done()

          transitions:
            A: '*': (data, callback) ->
              callback 'A*'
            '*': '*': (data, callback) ->
              callback '**'

        new TestState autostart: yes

  describe 'handling of 2 state machines simultaneously', ->
    it 'preserves local variables in state events', (done) ->
      locals = []
      class TestState extends NodeState
        constructor: (@local) ->
          super autostart: yes

        states:
          A:
            Enter: ->
              locals.push @local
              if locals.length is 2
                (1 in locals).should.be.ok
                (2 in locals).should.be.ok
                done()

      new TestState(1)
      new TestState(2)

    it 'preserves local variables in transitions', ->
      locals = []
      class TestState extends NodeState
        constructor: (@local) ->
          super autostart: yes

        states:
          A: {}
          B: {}

        transitions:
          A:
            B: ->
              locals.push @local
              if locals.length is 2
                (1 in locals).should.be.ok
                (2 in locals).should.be.ok
                done()

      new TestState(1)
      new TestState(2)

  describe 'start/stop', ->
    it 'does not call event callbacks after stop', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: ->
              @stop()
              @raise 'Foo'
              done()
            Foo: ->
              done 'event callback called'

      new TestState autostart: yes

    it 'does not call wait callbacks after stop', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: ->
              @wait 10
              @stop()
              setTimeout done, 10
            WaitTimeout: ->
              done 'wait timeout called'

      new TestState autostart: yes

    it 'clears the wait timeout after stop', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: ->
              @wait 10
              @stop()
              setTimeout =>
                @_current_timeout._called.should.be.false
                done()
              , 10
            WaitTimeout: ->
              done 'wait timeout called'

      new TestState autostart: yes

    it 'enters the last state on start', (done) ->
      class TestState extends NodeState
        constructor: ->
          @enteredB = no
          super

        states:
          A:
            Enter: ->
              done('entered state A after B') if @enteredB
              @goto 'B'
          B:
            Enter: ->
              return done() if @enteredB

              @enteredB = yes
              @stop()
              process.nextTick => @start()

      new TestState autostart: yes

    it 'passes data provided to start to last state', (done) ->
      class TestState extends NodeState
        constructor: ->
          @enteredB = no
          super

        states:
          A:
            Enter: ->
              done('entered state A after B') if @enteredB
              @goto 'B'
          B:
            Enter: (data) ->
              if @enteredB
                data.should.equal 'data-goes-here'
                done()
              else
                @enteredB = yes
                @stop()
                process.nextTick => @start 'data-goes-here'

      new TestState autostart: yes

  describe 'enable/disable', ->
    it 'does not call event callbacks after disable', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: ->
              @disable()
              @raise 'Foo'
              done()
            Foo: ->
              done 'event callback called'

      new TestState autostart: yes

    it 'makes goto no-op after disable', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @disable()
            @goto 'B'
            done()
          B: Enter: ->
            done 'in B'

      new TestState autostart: yes

    it 'does not call callbacks wrapped in wrapCb after disable', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            setTimeout(
              @wrapCb -> done 'wrapped callback called'
              10
            )
            @disable()
            setTimeout done, 10

      new TestState autostart: yes

    it 'enables goto after enable', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @disable()
            @enable()
            @goto 'B'
          B: Enter: ->
            done()

      new TestState autostart: yes

    it 'goes to specified state after enable(stateName)', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @disable()
            @enable 'B', 'b-data'
          B: Enter: (data) ->
            data.should.equal 'b-data'
            done()

      new TestState autostart: yes
