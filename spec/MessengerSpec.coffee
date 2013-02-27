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
