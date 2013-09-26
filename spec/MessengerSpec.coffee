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

server = success = error = null

serverBeforeEach = ->
    gm = $.globalMessenger()
    server = sinon.fakeServer.create()

    server.respondWith "GET", "/200", [200, {}, '{}']
    server.respondWith "GET", "/404", [404, {}, '{}']
    server.respondWith "GET", "/500", [500, {}, '{}']

    server.autoRespond = true

    success = sinon.spy()
    error = sinon.spy()


serverAfterEach = ->
    do server.restore

describe 'the global messenger', () ->
    beforeEach beforeEachFunc
    afterEach afterEachFunc

    it 'should be totally awesome', () ->
        itTotallyIs = true
        expect(itTotallyIs).toBe(true)
    
    it 'should be the same as $.globalMessenger', () ->
        expect($.globalMessenger).toBe(Messenger)

    it 'should be removed when noConflict is called', () ->
        _prevMessenger = Messenger

        Messenger.noConflict()
        expect(Messenger).toBe(undefined)

        window.Messenger = _prevMessenger

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

    it 'should respect maxMessages', ->
        Messenger.instance?.hideAll()

        Messenger.instance = null

        m = Messenger({'maxMessages': 2})
        m.post "a"
        m.post "b"
        m.post "c"
        m.post "d"

        expect($('.messenger-message-slot.messenger-shown').length).toBe(2)

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

    it 'should hide in the time specified', ->
        spy = start = end = null
        runs ->
            start = +(new Date)
            msg = gm.post
                message: 'test'
                hideAfter: 0.05

            msg.on 'hide', ->
                end = +(new Date)

            spies.push spy = sinon.spy(msg, 'hide')
            
            expect(spy.called).toBe(false)

        waitsFor ->
            end
        , 100

        runs ->
            expect(spy.calledOnce).toBe(true)

            time = end - start
            expect(Math.round(time / 10)).toBe(5)

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

    it 'should accept a promise-based action', ->
        promise = $.Deferred()

        message = gm.expectPromise (-> promise),
          successMessage: 'test'

        promise.resolve()

        expect(message.options.message).toBe('test')
        expect(message.options.type).toBe('success')

describe 'actions', ->
    beforeEach beforeEachFunc

    getActions = (msg) ->
        $(msg.el).find('.messenger-actions')

    getAction = (msg, key) ->
        $actions = getActions(msg)

        $actions.find("[data-action='#{ key }']")

    it 'should show buttons for defined actions', ->
        msg = gm.post
            message: 'test'
            actions:
                x:
                    label: 'y'

        expect(getAction(msg, 'x').length).toBe(1)
        expect(getAction(msg, 'x').find("a").text()).toBe('y')

    it 'should call callback when action is clicked', ->
        spy = sinon.spy()

        msg = gm.post
            message: 'test'
            actions:
                x:
                    action: spy

        expect(spy.called).toBe(false)

        getAction(msg, 'x').find("a").click()

        expect(spy.calledOnce).toBe(true)

    it 'should fire event when action is clicked', ->
        spy = sinon.spy()

        msg = gm.post
            message: 'test'
            actions:
                x:
                    action: ->

        msg.on 'action:x', spy

        expect(spy.called).toBe(false)

        getAction(msg, 'x').find("a").click()

        expect(spy.calledOnce).toBe(true)

describe 'do event bindings', ->
    beforeEach serverBeforeEach
    afterEach serverAfterEach

    it 'should allow events to be bound based on the state of the message', ->
        spy = sinon.spy()
        msg = null

        runs ->
            msg = gm.do
                events:
                    'success click': spy
            ,
                {url: '/200', success, error}

        waits 10

        runs ->
            # We want this class added when the entire message is clickable
            expect($(msg.el).find('.messenger-message').hasClass('messenger-clickable')).toBe(true)

            expect(spy.called).toBe(false)

            $(msg.el).click()
            expect(spy.calledOnce).toBe(true)

    it 'should allow events to be bound on elements in the message', ->
        spy = sinon.spy()
        msg = null

        runs ->
            msg = gm.do
                successMessage: 'Test <span data-name="bob">Bla</span>'
                events:
                    'success click span[data-name="bob"]': spy

            ,
                {url: '/200', success, error}

        waits 10

        runs ->
            expect($(msg.el).find('.messenger-message').hasClass('messenger-clickable')).toBe(false)

            expect(spy.called).toBe(false)

            $(msg.el).click()
            expect(spy.called).toBe(false)

            $(msg.el).find('span[data-name="bob"]').click()
            expect(spy.calledOnce).toBe(true)
    
describe 'do ajax', ->

    shouldBe = (result) ->
        waits 10

        runs ->
            expect(success.callCount).toBe(+(result is 'success'))
            expect(error.callCount).toBe(+(result is 'error'))

    beforeEach serverBeforeEach
    afterEach serverAfterEach

    it 'should make ajax requests by default', ->
        runs ->
            gm.do {}, {url: '/200'}

        waits 10

        runs ->
            expect(server.requests.length).toBe(1)

    it 'should call success once when the request succeeds', ->
        runs ->
            gm.do {}, {url: '/200', success, error}
    
        shouldBe 'success'
        
    it 'should call error once when the request 404s', ->
        runs ->
            gm.do {}, {url: '/404', success, error}

        shouldBe 'error'

    it 'should call error once when the request 500s', ->
        runs ->
            gm.do {retry: {allow: false}}, {url: '/500', success, error}

        shouldBe 'error'

    it 'should not retry 400s', ->
        runs ->
            gm.do
                retry:
                    allow: 3
                    delay: .01
            ,
                {url: '/404', success, error}

        waits 50

        runs ->
            expect(server.requests.length).toBe(1)

    it 'should not retry if auto is false', ->
        runs ->
            gm.do
                retry:
                    auto: false
                    allow: 3
                    delay: 0.01
            ,
                {url: '/500', success, error}

        waits 50

        runs ->
            expect(server.requests.length).toBe(1)

    it 'should retry the specified number of times when the request 500s', ->
        runs ->
            gm.do
                retry:
                    allow: 3
                    delay: .01
            ,
                {url: '/500', success, error}

        waits 100

        runs ->
            expect(server.requests.length).toBe(3)
    

    it 'should stop retrying on success', ->
        i = 0
        resp = (req) ->
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
            expect(server.requests.length).toBe(3)
            expect(success.calledOnce).toBe(true)

    it 'should show error message on errors', ->
        msg = null
        runs ->
            msg = gm.do
                errorMessage: 'OH'
                successMessage: 'X'
                progressMessage: 'X'
            ,
                {url: '/404', success, error}

        waits 10

        runs ->
            expect(msg.options.message).toBe('OH')
            expect(msg.options.type).toBe('error')
            expect(msg.shown).toBe(true)

    it 'should show success message on success', ->
        msg = null
        runs ->
            msg = gm.do
                successMessage: 'WEEE'
                errorMessage: 'X'
                progressMessage: 'X'
            ,
                {url: '/200', success, error}

        waits 10

        runs ->
            expect(msg.options.message).toBe('WEEE')
            expect(msg.options.type).toBe('success')
            expect(msg.shown).toBe(true)

    it 'should show progress message', ->
        msg = null

        server.autoRespond = false

        runs ->
            msg = gm.do
                errorMessage: 'X'
                successMessage: 'Y'
                progressMessage: '...'
            ,
                {'url': '/200', success, error}

        setTimeout ->
            server.respond()
        , 50

        waits 10

        runs ->
            expect(msg.options.message).toBe('...')
            expect(msg.options.type).toBe('info')
            expect(msg.shown).toBe(true)

        waits 50

        runs ->
            expect(msg.options.message).toBe('Y')
            expect(msg.options.type).toBe('success')
            expect(msg.shown).toBe(true)

    it 'shouldn\'t show a success message if there is no message defined', ->
        msg = null

        runs ->
            msg = gm.do {}, {'url': '/200', success, error}

        waits 10

        runs ->
            expect(msg.shown).toBe(false)

    it 'should let message contents be overridden by string messages', ->
        msg = null

        runs ->
            msg = gm.do
                successMessage: 'X'
            ,
                url: '/200',
                error: error,
                success: -> 'YAA'

        waits 10

        runs ->
            expect(msg.options.message).toBe('YAA')
            expect(msg.shown).toBe(true)

    it 'should let message contents be overridden by message configs', ->

        msg = null

        runs ->
            msg = gm.do
                successMessage: 'X'
            ,
                url: '/200',
                error: error,
                success: -> {
                  type: 'error'
                }

        waits 10

        runs ->
            expect(msg.options.type).toBe('error')

    it 'should let message contents be defined', ->
        msg = null

        runs ->
            msg = gm.do {},
                url: '/200',
                error: error,
                success: -> 'MHUM'

        waits 10

        runs ->
            expect(msg.options.message).toBe('MHUM')
            expect(msg.shown).toBe(true)

    it 'should let messages be hidden by handlers', ->
        msg = null

        runs ->
            msg = gm.do {},
                url: '/200',
                error: error,
                success: -> false

        waits 10

        runs ->
            expect(msg.shown).toBe(false)

    #
    # As of 1.3.0 we have 75% code coverage across 50% of branches
    #
    # To Be Tested:
    #
    # - classes being applied / removed
    # - the updating of the countdown / phrase
    # - Backbone hook / hideAfterNavigate (both pre and post Backbone 0.9.9)
    # - aborted requests not showing error message
    # - ignoreErrorCodes
    # - $.fn.messenger
    # - cancel
    # - formatTime
    # - findById
    # - message ids / singleton
    # - show / hide message events (+ re wasShown)
    # - show calling message.render if not already rendered
    # - message.update with string argument
    # - message without hideAfter not hiding
    # - scrollTo doing nothing if options.scroll is false
    # - timeSinceUpdate (if it can't just be removed)
    # - close button
    # - action abort on message cancel
    # - _normalizeResponse doing reasonable things
    # - showSuccessWithoutError
    # - xhr abort responses not triggering error messages
    # - automatic retry delay scaling
    # - hideAfter always occuring after delay has completed
    # - cancel action on do
    # - globalMessenger
    #   - injection locations
    #   - moving of messages when a better location shows up
    #   - adding / removing classes
    #   - passing in instance
