NodeState = require '../src/nodestate'
should = require('chai').should()

describe 'NodeState', ->
  describe 'initial state', ->
    it 'uses first given state as initial state', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: done
          B: Enter: ->
            'in B'.should.not.exist
            done()

      new TestState().start()

    it 'honors initial_state over first given state', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: ->
              'in A'.should.not.exist
              done()
          B: Enter: done

      new TestState(initial_state: 'B').start()

  describe 'autostart', ->
    it 'does not enter initial state if autostart is false', (done) ->
      goto_called = false

      class TestState extends NodeState
        states:
          A: Enter: done

      new TestState autostart: no
      # raise 'done() called multiple times' if A:Enter is called
      done()

    it 'does enter initial state if autostart is true', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: done

      new TestState autostart: yes

  describe 'wait', ->
    it 'fires WaitTimeout event after calling wait', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: -> @wait 50
            WaitTimeout: -> done()

      new TestState autostart: yes

    it 'cancels the wait timer when transitioning to another state', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: (data) ->
              @wait 50
              @goto 'B'
            WaitTimeout: (duration, data) ->
              'wait timeout in A'.should.not.exist
              done()
          B:
            Enter: ->
              # 'done() called multiple called' is raised in wait timeout
              done()
            WaitTimeout: (duration, data) ->
              'wait timeout in B'.should.not.exist
              done()

      new TestState autostart: yes

    it 'cancels the wait timer when unwait is called', (done) ->
      class TestState extends NodeState
        states:
          A:
            Enter: (data) ->
              @wait 50
              @raise 'CancelTimer'
            CancelTimer: (data) ->
              @unwait()
              # 'done() called multiple times' is raised in wait timeout
              done()
            WaitTimeout: (duration, data) ->
              'wait timeout in A'.should.not.exist
              done()

      new TestState autostart: yes

  describe 'goto', ->
    it 'enters specified state on goto', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> @goto 'B'
          B: Enter: done

      new TestState autostart: yes

    it 'retains current_data when goto is called with 1 argument', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: ->
            @goto 'B'
          B: Enter: (data) ->
            data.should.equal 1
            done()

      new TestState autostart: yes, initial_data: 1

    it 'honors goto calls from transition callbacks', (done) ->
      class TestState extends NodeState
        states:
          A: Enter: -> @goto 'B'
          B: {}
          C: Enter: done

        transitions:
          A: B: (data, callback) ->
            @goto 'C'

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
