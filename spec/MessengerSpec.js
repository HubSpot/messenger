(function() {
  var afterEachFunc, beforeEachFunc, error, gm, server, serverAfterEach, serverBeforeEach, spies, success, test_msg;

  gm = null;

  test_msg = 'light it up';

  spies = null;

  beforeEachFunc = function() {
    spies = [];
    return gm = $.globalMessenger();
  };

  afterEachFunc = function() {
    var spy, _i, _len, _results;
    gm = null;
    if (spies) {
      _results = [];
      for (_i = 0, _len = spies.length; _i < _len; _i++) {
        spy = spies[_i];
        if (spy) {
          try {
            _results.push(spy.restore());
          } catch (error) {

          }
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  server = success = error = null;

  serverBeforeEach = function() {
    gm = $.globalMessenger();
    server = sinon.fakeServer.create();
    server.respondWith("GET", "/200", [200, {}, '{}']);
    server.respondWith("GET", "/404", [404, {}, '{}']);
    server.respondWith("GET", "/500", [500, {}, '{}']);
    server.autoRespond = true;
    success = sinon.spy();
    return error = sinon.spy();
  };

  serverAfterEach = function() {
    return server.restore();
  };

  describe('the global messenger', function() {
    beforeEach(beforeEachFunc);
    afterEach(afterEachFunc);
    it('should be totally awesome', function() {
      var itTotallyIs;
      itTotallyIs = true;
      return expect(itTotallyIs).toBe(true);
    });
    it('should be the same as $.globalMessenger', function() {
      return expect($.globalMessenger).toBe(Messenger);
    });
    it('should be removed when noConflict is called', function() {
      var _prevMessenger;
      _prevMessenger = Messenger;
      Messenger.noConflict();
      expect(Messenger).toBe(void 0);
      return window.Messenger = _prevMessenger;
    });
    it('should create a new message on post', function() {
      var msg, newMessageSpy;
      newMessageSpy = sinon.spy(gm, 'newMessage');
      spies.push(newMessageSpy);
      msg = gm.post(test_msg);
      return expect(newMessageSpy.called).toBeTruthy();
    });
    it('should be able to hide all messages', function() {
      var msg1, msg2, spy1, spy2, yeahBuddy;
      yeahBuddy = 'cabs are ';
      msg1 = gm.post(yeahBuddy + ' here');
      msg2 = gm.post(yeahBuddy + ' not here');
      spy1 = sinon.spy(msg1, 'hide');
      spy2 = sinon.spy(msg2, 'hide');
      gm.hideAll();
      expect(spy1.called).toBeTruthy();
      return expect(spy2.called).toBeTruthy();
    });
    return it('should respect maxMessages', function() {
      var m, _ref;
      if ((_ref = Messenger.instance) != null) {
        _ref.hideAll();
      }
      Messenger.instance = null;
      m = Messenger({
        'maxMessages': 2
      });
      m.post("a");
      m.post("b");
      m.post("c");
      m.post("d");
      return expect($('.messenger-message-slot.messenger-shown').length).toBe(2);
    });
  });

  describe('a message', function() {
    beforeEach(beforeEachFunc);
    afterEach(afterEachFunc);
    it('should cancel timers on cancel', function() {
      var msg, spy;
      msg = gm.post(test_msg);
      spy = sinon.spy(msg, 'clearTimers');
      spies.push(spy);
      msg.cancel();
      return expect(spy.called).toBeTruthy();
    });
    it('should fire events properly', function() {
      var eventName, fulfilled, msg;
      msg = gm.post(test_msg);
      fulfilled = false;
      eventName = 'wtf_mate';
      msg.on(eventName, function() {
        return expect(true).toBeTruthy();
      });
      return msg.trigger('wtf_mate');
    });
    it('should re-render a message on update', function() {
      var msg, renderSpy;
      msg = gm.post(test_msg);
      renderSpy = sinon.spy(msg, 'render');
      spies.push(renderSpy);
      msg.update({
        message: test_msg
      });
      return expect(renderSpy.called).toBeTruthy();
    });
    it('should trigger update event on update', function() {
      var msg, triggerSpy;
      msg = gm.post(test_msg);
      triggerSpy = sinon.spy(msg, 'trigger');
      spies.push(triggerSpy);
      msg.update({
        message: test_msg
      });
      return expect(triggerSpy.calledWith('update')).toBeTruthy();
    });
    it('should trigger hide event on hide', function() {
      var msg, spy;
      msg = gm.post(test_msg);
      spy = sinon.spy(msg, 'trigger');
      spies.push(spy);
      msg.hide();
      return expect(spy.calledWith('hide')).toBeTruthy();
    });
    it('should hide in the time specified', function() {
      var end, spy, start;
      spy = start = end = null;
      runs(function() {
        var msg;
        start = +(new Date);
        msg = gm.post({
          message: 'test',
          hideAfter: 0.05
        });
        msg.on('hide', function() {
          return end = +(new Date);
        });
        spies.push(spy = sinon.spy(msg, 'hide'));
        return expect(spy.called).toBe(false);
      });
      waitsFor(function() {
        return end;
      }, 100);
      return runs(function() {
        var time;
        expect(spy.calledOnce).toBe(true);
        time = end - start;
        return expect(Math.round(time / 10)).toBe(5);
      });
    });
    return it('should be able to be scrolled to', function() {
      var msg, spy;
      msg = gm.post(test_msg);
      $.scrollTo = function() {};
      spy = sinon.stub($, 'scrollTo');
      spies.push(spy);
      msg.scrollTo();
      return expect(spy.called).toBeTruthy();
    });
  });

  describe('do', function() {
    beforeEach(beforeEachFunc);
    it('should do the action once', function() {
      var spy;
      spy = sinon.spy();
      gm["do"]({
        action: spy
      });
      return expect(spy.calledOnce).toBeTruthy();
    });
    it('should pass in success and error callbacks', function() {
      var opts, spy;
      spy = sinon.spy();
      gm["do"]({
        action: spy
      });
      opts = spy.args[0][0];
      expect(typeof opts.success).toBe('function');
      return expect(typeof opts.error).toBe('function');
    });
    it('should pass the args into the action', function() {
      var spy;
      spy = sinon.spy();
      gm["do"]({
        action: spy
      }, {
        arg: 5
      });
      return expect(spy.calledWithMatch({
        arg: 5
      })).toBeTruthy();
    });
    it('should return the message', function() {
      var message;
      message = gm["do"]();
      expect(typeof message).toBe('object');
      return expect(message.messenger).toBeDefined();
    });
    return it('should accept a promise-based action', function() {
      var message, promise;
      promise = $.Deferred();
      message = gm.expectPromise((function() {
        return promise;
      }), {
        successMessage: 'test'
      });
      promise.resolve();
      expect(message.options.message).toBe('test');
      return expect(message.options.type).toBe('success');
    });
  });

  describe('actions', function() {
    var getAction, getActions;
    beforeEach(beforeEachFunc);
    getActions = function(msg) {
      return $(msg.el).find('.messenger-actions');
    };
    getAction = function(msg, key) {
      var $actions;
      $actions = getActions(msg);
      return $actions.find("[data-action='" + key + "']");
    };
    it('should show buttons for defined actions', function() {
      var msg;
      msg = gm.post({
        message: 'test',
        actions: {
          x: {
            label: 'y'
          }
        }
      });
      expect(getAction(msg, 'x').length).toBe(1);
      return expect(getAction(msg, 'x').find("a").text()).toBe('y');
    });
    it('should call callback when action is clicked', function() {
      var msg, spy;
      spy = sinon.spy();
      msg = gm.post({
        message: 'test',
        actions: {
          x: {
            action: spy
          }
        }
      });
      expect(spy.called).toBe(false);
      getAction(msg, 'x').find("a").click();
      return expect(spy.calledOnce).toBe(true);
    });
    return it('should fire event when action is clicked', function() {
      var msg, spy;
      spy = sinon.spy();
      msg = gm.post({
        message: 'test',
        actions: {
          x: {
            action: function() {}
          }
        }
      });
      msg.on('action:x', spy);
      expect(spy.called).toBe(false);
      getAction(msg, 'x').find("a").click();
      return expect(spy.calledOnce).toBe(true);
    });
  });

  describe('do event bindings', function() {
    beforeEach(serverBeforeEach);
    afterEach(serverAfterEach);
    it('should allow events to be bound based on the state of the message', function() {
      var msg, spy;
      spy = sinon.spy();
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          events: {
            'success click': spy
          }
        }, {
          url: '/200',
          success: success,
          error: error
        });
      });
      waits(10);
      return runs(function() {
        expect($(msg.el).find('.messenger-message').hasClass('messenger-clickable')).toBe(true);
        expect(spy.called).toBe(false);
        $(msg.el).click();
        return expect(spy.calledOnce).toBe(true);
      });
    });
    return it('should allow events to be bound on elements in the message', function() {
      var msg, spy;
      spy = sinon.spy();
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          successMessage: 'Test <span data-name="bob">Bla</span>',
          events: {
            'success click span[data-name="bob"]': spy
          }
        }, {
          url: '/200',
          success: success,
          error: error
        });
      });
      waits(10);
      return runs(function() {
        expect($(msg.el).find('.messenger-message').hasClass('messenger-clickable')).toBe(false);
        expect(spy.called).toBe(false);
        $(msg.el).click();
        expect(spy.called).toBe(false);
        $(msg.el).find('span[data-name="bob"]').click();
        return expect(spy.calledOnce).toBe(true);
      });
    });
  });

  describe('do ajax', function() {
    var shouldBe;
    shouldBe = function(result) {
      waits(10);
      return runs(function() {
        expect(success.callCount).toBe(+(result === 'success'));
        return expect(error.callCount).toBe(+(result === 'error'));
      });
    };
    beforeEach(serverBeforeEach);
    afterEach(serverAfterEach);
    it('should make ajax requests by default', function() {
      runs(function() {
        return gm["do"]({}, {
          url: '/200'
        });
      });
      waits(10);
      return runs(function() {
        return expect(server.requests.length).toBe(1);
      });
    });
    it('should call success once when the request succeeds', function() {
      runs(function() {
        return gm["do"]({}, {
          url: '/200',
          success: success,
          error: error
        });
      });
      return shouldBe('success');
    });
    it('should call error once when the request 404s', function() {
      runs(function() {
        return gm["do"]({}, {
          url: '/404',
          success: success,
          error: error
        });
      });
      return shouldBe('error');
    });
    it('should call error once when the request 500s', function() {
      runs(function() {
        return gm["do"]({
          retry: {
            allow: false
          }
        }, {
          url: '/500',
          success: success,
          error: error
        });
      });
      return shouldBe('error');
    });
    it('should not retry 400s', function() {
      runs(function() {
        return gm["do"]({
          retry: {
            allow: 3,
            delay: .01
          }
        }, {
          url: '/404',
          success: success,
          error: error
        });
      });
      waits(50);
      return runs(function() {
        return expect(server.requests.length).toBe(1);
      });
    });
    it('should not retry if auto is false', function() {
      runs(function() {
        return gm["do"]({
          retry: {
            auto: false,
            allow: 3,
            delay: 0.01
          }
        }, {
          url: '/500',
          success: success,
          error: error
        });
      });
      waits(50);
      return runs(function() {
        return expect(server.requests.length).toBe(1);
      });
    });
    it('should retry the specified number of times when the request 500s', function() {
      runs(function() {
        return gm["do"]({
          retry: {
            allow: 3,
            delay: .01
          }
        }, {
          url: '/500',
          success: success,
          error: error
        });
      });
      waits(100);
      return runs(function() {
        return expect(server.requests.length).toBe(3);
      });
    });
    it('should stop retrying on success', function() {
      var i, resp;
      i = 0;
      resp = function(req) {
        if (++i >= 3) {
          return req.respond(200, {}, '{}');
        } else {
          return req.respond(504, {}, '{}');
        }
      };
      server.respondWith("GET", "/x", resp);
      runs(function() {
        return gm["do"]({
          retry: {
            delay: .01
          }
        }, {
          url: '/x',
          success: success,
          error: error
        });
      });
      waits(100);
      return runs(function() {
        expect(i).toBe(3);
        expect(server.requests.length).toBe(3);
        return expect(success.calledOnce).toBe(true);
      });
    });
    it('should show error message on errors', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          errorMessage: 'OH',
          successMessage: 'X',
          progressMessage: 'X'
        }, {
          url: '/404',
          success: success,
          error: error
        });
      });
      waits(10);
      return runs(function() {
        expect(msg.options.message).toBe('OH');
        expect(msg.options.type).toBe('error');
        return expect(msg.shown).toBe(true);
      });
    });
    it('should show success message on success', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          successMessage: 'WEEE',
          errorMessage: 'X',
          progressMessage: 'X'
        }, {
          url: '/200',
          success: success,
          error: error
        });
      });
      waits(10);
      return runs(function() {
        expect(msg.options.message).toBe('WEEE');
        expect(msg.options.type).toBe('success');
        return expect(msg.shown).toBe(true);
      });
    });
    it('should show progress message', function() {
      var msg;
      msg = null;
      server.autoRespond = false;
      runs(function() {
        return msg = gm["do"]({
          errorMessage: 'X',
          successMessage: 'Y',
          progressMessage: '...'
        }, {
          'url': '/200',
          success: success,
          error: error
        });
      });
      setTimeout(function() {
        return server.respond();
      }, 50);
      waits(10);
      runs(function() {
        expect(msg.options.message).toBe('...');
        expect(msg.options.type).toBe('info');
        return expect(msg.shown).toBe(true);
      });
      waits(50);
      return runs(function() {
        expect(msg.options.message).toBe('Y');
        expect(msg.options.type).toBe('success');
        return expect(msg.shown).toBe(true);
      });
    });
    it('shouldn\'t show a success message if there is no message defined', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({}, {
          'url': '/200',
          success: success,
          error: error
        });
      });
      waits(10);
      return runs(function() {
        return expect(msg.shown).toBe(false);
      });
    });
    it('should let message contents be overridden by string messages', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          successMessage: 'X'
        }, {
          url: '/200',
          error: error,
          success: function() {
            return 'YAA';
          }
        });
      });
      waits(10);
      return runs(function() {
        expect(msg.options.message).toBe('YAA');
        return expect(msg.shown).toBe(true);
      });
    });
    it('should let message contents be overridden by message configs', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({
          successMessage: 'X'
        }, {
          url: '/200',
          error: error,
          success: function() {
            return {
              type: 'error'
            };
          }
        });
      });
      waits(10);
      return runs(function() {
        return expect(msg.options.type).toBe('error');
      });
    });
    it('should let message contents be defined', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({}, {
          url: '/200',
          error: error,
          success: function() {
            return 'MHUM';
          }
        });
      });
      waits(10);
      return runs(function() {
        expect(msg.options.message).toBe('MHUM');
        return expect(msg.shown).toBe(true);
      });
    });
    return it('should let messages be hidden by handlers', function() {
      var msg;
      msg = null;
      runs(function() {
        return msg = gm["do"]({}, {
          url: '/200',
          error: error,
          success: function() {
            return false;
          }
        });
      });
      waits(10);
      return runs(function() {
        return expect(msg.shown).toBe(false);
      });
    });
  });

}).call(this);
