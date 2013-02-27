describe '$.globalMessenger', () ->
    # define variables here to be used in beforeEach/afterEach
    gm = null
    test_msg = 'light it up'
    spies = null

    beforeEach () ->
        spies = []
        gm = $.globalMessenger()

    afterEach () ->
        gm = null

        if spies
            for spy in spies
                if spy
                    try
                        spy.restore()
                    catch error

    it 'should create a new message on post', () ->
        newMessageSpy = sinon.spy(gm, 'newMessage')
        spies.push newMessageSpy
        msg = gm.post test_msg
        expect(newMessageSpy.called).toBe(true)

    it 'should re-render a message on update', () ->
        msg = gm.post test_msg
        renderSpy = sinon.spy(msg, 'render')
        spies.push renderSpy
        msg.update { message: test_msg }
        expect(renderSpy.called).toBe(true)

    it 'should trigger update event on update', () ->
        msg = gm.post test_msg
        triggerSpy = sinon.spy(msg, 'trigger')
        spies.push triggerSpy
        msg.update { message: test_msg }
        expect(triggerSpy.called).toBe(true)