(function() {
  var afterEachFunc, beforeEachFunc, gm, spies, test_msg;

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

  describe('the global messenger', function() {
    beforeEach(beforeEachFunc);
    afterEach(afterEachFunc);
    it('should be totally awesome', function() {
      var itTotallyIs;
      itTotallyIs = true;
      return expect(itTotallyIs).toBe(true);
    });
    it('should create a new message on post', function() {
      var msg, newMessageSpy;
      newMessageSpy = sinon.spy(gm, 'newMessage');
      spies.push(newMessageSpy);
      msg = gm.post(test_msg);
      return expect(newMessageSpy.called).toBeTruthy();
    });
    return it('should be able to hide all messages', function() {
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
    return it('should return the message', function() {
      var message;
      message = gm["do"]();
      expect(typeof message).toBe('object');
      return expect(message.messenger).toBeDefined();
    });
  });

  describe('do ajax', function() {
    var defer, error, server, shouldBe, success;
    server = success = error = null;
    defer = function(func) {
      return setTimeout(func, 1);
    };
    shouldBe = function(result) {
      waits(10);
      return runs(function() {
        expect(success.callCount).toBe(+(result === 'success'));
        return expect(error.callCount).toBe(+(result === 'error'));
      });
    };
    beforeEach(function() {
      gm = $.globalMessenger();
      server = sinon.fakeServer.create();
      server.respondWith("GET", "/200", [200, {}, '{}']);
      server.respondWith("GET", "/404", [404, {}, '{}']);
      server.respondWith("GET", "/500", [500, {}, '{}']);
      success = sinon.spy();
      return error = sinon.spy();
    });
    afterEach(function() {
      return server.restore();
    });
    it('should make ajax requests by default', function() {
      runs(function() {
        gm["do"]({}, {
          url: '/200'
        });
        return server.respond();
      });
      waits(10);
      return runs(function() {
        console.log(server);
        return expect(server.requests.length).toBe(1);
      });
    });
    it('should call success once when the request succeeds', function() {
      runs(function() {
        gm["do"]({}, {
          url: '/200',
          success: success,
          error: error
        });
        return server.respond();
      });
      return shouldBe('success');
    });
    it('should call error once when the request 404s', function() {
      runs(function() {
        gm["do"]({}, {
          url: '/404',
          success: success,
          error: error
        });
        return server.respond();
      });
      return shouldBe('error');
    });
    it('should call error once when the request 500s', function() {
      runs(function() {
        gm["do"]({}, {
          url: '/500',
          success: success,
          error: error
        });
        return server.respond();
      });
      return shouldBe('error');
    });
    it('should not retry 400s', function() {
      var resp;
      resp = sinon.spy(function(req) {
        return req.respond(400, {}, '{}');
      });
      server.respondWith("GET", "/x", resp);
      runs(function() {
        return gm["do"]({
          retry: {
            allow: 3,
            delay: .01
          }
        }, {
          url: '/x',
          success: success,
          error: error
        });
      });
      waits(50);
      return runs(function() {
        return expect(server.requests.length).toBe(1);
      });
    });
    return it('should retry thrice when the request 500s', function() {
      var resp;
      resp = sinon.spy(function(req) {
        return req.respond(500, {}, '{}');
      });
      server.respondWith("GET", "/x", resp);
      runs(function() {
        gm["do"]({
          retry: {
            allow: 3,
            delay: .01
          }
        }, {
          url: '/x',
          success: success,
          error: error
        });
        return server.respond();
      });
      waits(50);
      return runs(function() {
        return expect(server.requests.length).toBe(3);
      });
    });
  });

}).call(this);
