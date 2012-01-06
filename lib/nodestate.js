(function() {
  var EventEmitter2, NodeState,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  EventEmitter2 = require('eventemitter2').EventEmitter2;

  NodeState = (function() {

    function NodeState(config) {
      var events, prefix, state_name, _base, _base2, _base3, _base4, _i, _len, _name, _ref, _ref2,
        _this = this;
      this.config = config;
      this.stop = __bind(this.stop, this);
      this.start = __bind(this.start, this);
      this.raise = __bind(this.raise, this);
      this.wait = __bind(this.wait, this);
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
      (_base2 = this.config).transitions || (_base2.transitions = {});
      (_base3 = this.config).autostart || (_base3.autostart = false);
      _ref = this.config.states;
      for (state_name in _ref) {
        events = _ref[state_name];
        _ref2 = ['post', 'pre', 'on'];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          prefix = _ref2[_i];
          (_base4 = this.config.transitions)[_name = "" + prefix + state_name] || (_base4[_name] = function(data, callback) {
            return callback(data);
          });
        }
      }
      this.goto = function(state_name, data) {
        var post_transition;
        console.log("received " + data);
        _this.current_data = data || _this.current_data;
        console.log("current data " + _this.current_data);
        post_transition = _this.config.transitions["post" + _this.current_state_name];
        return post_transition(_this.current_data, function(data) {
          var callback, event_name, pre_transition, _ref3;
          if (data == null) data = _this.current_data;
          _this.current_data = data;
          if (_this._current_timeout) clearTimeout(_this._current_timeout);
          _ref3 = _this.current_state;
          for (event_name in _ref3) {
            callback = _ref3[event_name];
            _this._notifier.removeListener(event_name, callback);
          }
          pre_transition = _this.config.transitions["pre" + state_name];
          return pre_transition(_this.current_data, function(data) {
            var callback, event_name, on_transition, _ref4;
            if (data == null) data = _this.current_data;
            _this.current_data = data;
            _this.current_state_name = state_name;
            _this.current_state = _this.config.states[_this.current_state_name];
            _ref4 = _this.current_state;
            for (event_name in _ref4) {
              callback = _ref4[event_name];
              _this._notifier.on(event_name, callback);
            }
            on_transition = _this.config.transitions["on" + state_name];
            return on_transition(_this.current_data, function(data) {
              if (data == null) data = _this.current_data;
              return _this.current_data = data;
            });
          });
        });
      };
      if (this.config.autostart) this.goto(this.current_state_name);
    }

    NodeState.prototype.wait = function(milliseconds) {
      var _this = this;
      return this._current_timeout = setTimeout((function() {
        return _this._notifier.emit('WaitTimeout', milliseconds, _this.current_data);
      }), milliseconds);
    };

    NodeState.prototype.raise = function(event_name, data) {
      return this._notifier.emit(event_name, data);
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
