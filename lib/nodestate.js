(function() {
  var EventEmitter2, NodeState,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  EventEmitter2 = require('eventemitter2').EventEmitter2;

  NodeState = (function() {

    function NodeState(config) {
      var events, state_name, _base, _base2, _base3, _base4, _ref,
        _this = this;
      this.config = config;
      this.stop = __bind(this.stop, this);
      this.start = __bind(this.start, this);
      this.wait = __bind(this.wait, this);
      this.raise = __bind(this.raise, this);
      this._notifier = new EventEmitter2({
        wildcard: true
      });
      (_base = this.config).initial_state || (_base.initial_state = ((function() {
        var _results;
        _results = [];
        for (state_name in this.config.states) {
          _results.push(state_name);
        }
        return _results;
      }).call(this))[0]);
      this.current_state_name = this.config.initial_state;
      this.current_state = this.config.states[this.current_state_name];
      this.current_data = config.initial_data || {};
      this._current_timeout = null;
      (_base2 = this.config).transitions || (_base2.transitions = []);
      (_base3 = this.config).autostart || (_base3.autostart = false);
      _ref = this.config.states;
      for (state_name in _ref) {
        events = _ref[state_name];
        (_base4 = this.config.states[state_name])['Enter'] || (_base4['Enter'] = function(data) {
          return this.current_data = data;
        });
      }
      this.goto = function(state_name, data) {
        var callback, doTransition, event_name, previous_state_name, transition, transitions, _i, _len, _ref2, _ref3, _ref4;
        _this.current_data = data || _this.current_data;
        previous_state_name = _this.current_state_name;
        if (_this._current_timeout) clearTimeout(_this._current_timeout);
        _ref2 = _this.current_state;
        for (event_name in _ref2) {
          callback = _ref2[event_name];
          console.log("removing listener for event: " + event_name);
          _this._notifier.removeListener(event_name, callback);
        }
        _this.current_state_name = state_name;
        _this.current_state = _this.config.states[_this.current_state_name];
        _ref3 = _this.current_state;
        for (event_name in _ref3) {
          callback = _ref3[event_name];
          console.log("registering listener for event: " + event_name);
          _this._notifier.on(event_name, callback);
        }
        transitions = [];
        _ref4 = _this.config.transitions;
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          transition = _ref4[_i];
          if ((transition[0] === previous_state_name || transition[0] === '*') && (transition[1] === _this.current_state_name || transition[1] === '*')) {
            transitions.push(transition);
          }
        }
        if (transitions.length) {
          doTransition = function(transition, data, remaining, isDone) {
            return transition[2](data, remaining, function(new_data, remaining) {
              if (remaining.length) {
                return doTransition(remaining[0], new_data, remaining, isDone);
              } else {
                return isDone(data);
              }
            });
          };
          return doTransition(transitions[0], _this.current_data, transitions.slice(1), function(data) {
            return _this._notifier.emit('Enter', _this.current_data);
          });
        } else {
          return _this._notifier.emit('Enter', _this.current_data);
        }
      };
      if (this.config.autostart) this.goto(this.current_state_name);
    }

    NodeState.prototype.raise = function(event_name, data) {
      return this._notifier.emit(event_name, data);
    };

    NodeState.prototype.wait = function(milliseconds) {
      var _this = this;
      return this._current_timeout = setTimeout((function() {
        return _this._notifier.emit('WaitTimeout', milliseconds, _this.current_data);
      }), milliseconds);
    };

    NodeState.prototype.start = function(data) {
      this.current_data || (this.current_data = data);
      return this.goto(this.current_state_name);
    };

    NodeState.prototype.stop = function() {
      return this._notifier.removeAllListeners();
    };

    return NodeState;

  })();

  module.exports = NodeState;

}).call(this);
