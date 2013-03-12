# define variables here to be used in beforeEach/afterEach
gm = null
test_msg = 'light it up'
spies = null

beforeEachFunc = () ->
    spies = []
    gm = $.globalMessenger()

afterEachFunc = () ->
    gm = null

    if spies
        for spy in spies
            if spy
                try
                    spy.restore()
                catch error

describe 'the global messenger', () ->
    beforeEach beforeEachFunc
    afterEach afterEachFunc

    it 'should be totally awesome', () ->
        itTotallyIs = true
        expect(itTotallyIs).toBe(true)
    
    it 'should create a new message on post', () ->
        newMessageSpy = sinon.spy(gm, 'newMessage')
        spies.push newMessageSpy
        msg = gm.post test_msg
        expect(newMessageSpy.called).toBeTruthy()

    it 'should be able to hide all messages', () ->
        yeahBuddy = 'cabs are '
        msg1 = gm.post yeahBuddy + ' here'
        msg2 = gm.post yeahBuddy + ' not here'
        spy1 = sinon.spy msg1, 'hide'
        spy2 = sinon.spy msg2, 'hide'
        gm.hideAll()
        expect(spy1.called).toBeTruthy()
        expect(spy2.called).toBeTruthy()

    # it 'should be able to hook into Backbone sync/ajax'

    

describe 'a message', () ->
    beforeEach beforeEachFunc
    afterEach afterEachFunc
    
    it 'should cancel timers on cancel', () ->
        msg = gm.post test_msg
        spy = sinon.spy(msg, 'clearTimers')
        spies.push spy
        msg.cancel()
        expect(spy.called).toBeTruthy()
    
    it 'should fire events properly', () ->
        msg = gm.post test_msg
        fulfilled = false
        eventName = 'wtf_mate'
        msg.on eventName, () ->
            expect(true).toBeTruthy()
        
        msg.trigger 'wtf_mate'

    it 'should re-render a message on update', () ->
        msg = gm.post test_msg
        renderSpy = sinon.spy(msg, 'render')
        spies.push renderSpy
        msg.update { message: test_msg }
        expect(renderSpy.called).toBeTruthy()

    it 'should trigger update event on update', () ->
        msg = gm.post test_msg
        triggerSpy = sinon.spy(msg, 'trigger')
        spies.push triggerSpy
        msg.update { message: test_msg }
        expect(triggerSpy.calledWith('update')).toBeTruthy()

    it 'should trigger hide event on hide', () ->
        msg = gm.post test_msg
        spy = sinon.spy(msg, 'trigger')
        spies.push spy
        msg.hide()
        expect(spy.calledWith('hide')).toBeTruthy()

    it 'should be able to be scrolled to', () ->
        msg = gm.post test_msg
        # stub this out this here to avoid including the dependency
        $.scrollTo = () ->
        spy = sinon.stub($, 'scrollTo')
        spies.push spy
        msg.scrollTo()
        expect(spy.called).toBeTruthy()


describe 'do', ->
    beforeEach beforeEachFunc

    it 'should do the action once', ->
        spy = sinon.spy()
        gm.do
            action: spy

        expect(spy.calledOnce).toBeTruthy()

    it 'should pass in success and error callbacks', ->
        spy = sinon.spy()
        gm.do
            action: spy

        opts = spy.args[0][0]
        expect(typeof opts.success).toBe('function')
        expect(typeof opts.error).toBe('function')

    it 'should pass the args into the action', ->
        spy = sinon.spy()
        gm.do
            action: spy
        ,
            arg: 5

        expect(spy.calledWithMatch({arg: 5})).toBeTruthy()

    it 'should return the message', ->
        message = gm.do()

        expect(typeof message).toBe('object')
        expect(message.messenger).toBeDefined()

describe 'do ajax', ->
    server = success = error = null

    defer = (func) ->
        setTimeout func, 1

    shouldBe = (result) ->
        waits 10

        runs ->
            expect(success.callCount).toBe(+(result is 'success'))
            expect(error.callCount).toBe(+(result is 'error'))

    beforeEach ->
        gm = $.globalMessenger()
        server = sinon.fakeServer.create()

        server.respondWith "GET", "/200", [200, {}, '{}']
        server.respondWith "GET", "/404", [404, {}, '{}']
        server.respondWith "GET", "/500", [500, {}, '{}']

        success = sinon.spy()
        error = sinon.spy()

    afterEach ->
        do server.restore

    it 'should make ajax requests by default', ->
        runs ->
            gm.do {}, {url: '/200'}

            server.respond()

        waits 10

        runs ->
            console.log server
            expect(server.requests.length).toBe(1)

    it 'should call success once when the request succeeds', ->
        runs ->
            gm.do {}, {url: '/200', success, error}

            server.respond()
    
        shouldBe 'success'
        
    it 'should call error once when the request 404s', ->
        runs ->
            gm.do {}, {url: '/404', success, error}

            server.respond()

        shouldBe 'error'

    it 'should call error once when the request 500s', ->
        runs ->
            gm.do {retry: {allow: false}}, {url: '/500', success, error}

            server.respond()

        shouldBe 'error'

    it 'should not retry 400s', ->
        resp = sinon.spy (req) ->
            req.respond 400, {}, '{}'
        
        server.respondWith "GET", "/x", resp

        runs ->
            gm.do
                retry:
                    allow: 3
                    delay: .01
            ,
                {url: '/x', success, error}

        waits 50

        runs ->
            expect(server.requests.length).toBe(1)

    it 'should retry the specified number of times when the request 500s', ->
        server.autoRespond = true

        resp = (req) ->
            req.respond 500, {}, '{}'

        server.respondWith "GET", "/x", resp

        runs ->
            gm.do
                retry:
                    allow: 3
                    delay: .01
            ,
                {url: '/x', success, error}

        waits 100

        runs ->
            expect(server.requests.length).toBe(3)
    

    it 'should stop retrying on success', ->
        server.autoRespond = true

        i = 0
        resp = (req) ->
            console.log req
            if ++i >= 3
                req.respond 200, {}, '{}'
            else
                req.respond 504, {}, '{}'

        server.respondWith "GET", "/x", resp

        runs ->
            gm.do
                retry:
                    delay: .01
            ,
                {url: '/x', success, error}


        waits 100

        runs ->
            expect(i).toBe(3)
            expect(success.calledOnce).toBe(true)

