$ = jQuery

class Message extends Backbone.View
    defaults:
        hideAfter: 10
        scroll: true

    constructor: (@messenger, @opts={}) ->
        @shown = false
        @rendered = false
        
        @opts = $.extend {}, @defaults, @opts

        super

    show: ->
        do @render

        @$el.show()

        @trigger('show') unless @shown

        @shown = true


    hide: ->
        @$el.hide()

        @trigger('hide') if @shown

        @shown = false

    update: (opts) ->
        $.extend(@opts, opts)

        @lastUpdate = new Date()
        
        @rendered = false
        
        @events = @opts.events

        do @render

        do @actionsToEvents
        do @delegateEvents

        do @checkClickable

        if @opts.hideAfter
            if @_hideTimeout?
                clearTimeout @_hideTimeout

            @_hideTimeout = setTimeout =>
                do @hide
            , @opts.hideAfter * 1000

        if @opts.hideOnNavigate
            if Backbone.history?
                Backbone.history.on 'route', =>
                    do @hide

    scrollTo: ->
        return unless @opts.scroll

        $.scrollTo @$el,
            duration: 400
            offset:
                left: 0
                top: -20

    timeSinceUpdate: ->
        return if @lastUpdate then ((new Date) - @lastUpdate) else null

    actionsToEvents: ->
        for name, act of @opts.actions
            @events["click a[href=##{ name }]"] = ((act) ->
                return (e) =>
                    do e.preventDefault
                    do e.stopPropagation

                    act.action(e)
            )(act)

    checkClickable: ->
        for name, evt of @events
            if name is 'click'
                @$el.addClass 'clickable'

    undelegateEvents: ->
        super

        @$el.removeClass 'clickable'

    parseActions: ->
        actions = []

        for name, act of @opts.actions
            n_act = $.extend {}, act
            n_act.name = name
            n_act.label ?= name

            actions.push n_act

        return actions

    template: (opts) ->
        $message = $ "<div class='message alert #{ opts.type } alert-#{ opts.type }'>#{ opts.message }</div>"

        $actions = $ '<div class="actions">'
        for action in opts.actions
            $action = $ '<span>'
            $action.attr 'data-action', action.name

            $link = $ '<a>'
            $link.attr 'href', "##{ action.name }"
            $link.html action.label

            $action.append $ '<span class="phrase">'
            $action.append $link
   
            $actions.append $action

        $message.append $actions
            
        $message

    render: ->
        if @rendered
            return

        if not @_hasSlot
            @setElement @messenger._reserveMessageSlot(@)

            @_hasSlot = true

        opts = $.extend {}, @opts,
            actions: do @parseActions

        @$el.addClass "#{ opts.type } alert-#{ opts.type }"
        @$el.html @template opts

        @rendered = true

class MagicMessage extends Message
    constructor: ->
        super

        @_timers = {}

    cancel: ->
        do @clearTimers
        do @hide

        if @_actionInstance? and @_actionInstance.abort?
            do @_actionInstance.abort

    clearTimers: ->
        for name, timer of @_timers
            clearTimeout timer

    render: ->
        super

        do @clearTimers

        for name, action of @opts.actions
            if action.auto
                @startCountdown name, action

    renderPhrase: (action, time) ->
        phrase = action.phrase.replace('TIME', @formatTime(time))
        return phrase

    formatTime: (time) ->
        pluralize = (num, str) ->
            num = Math.floor num

            if num != 1
                str = str + 's'

            return 'in ' + num + ' ' + str

        if Math.floor(time) == 0
            return 'now...'

        if time < 60
            return pluralize(time, 'second')

        time /= 60
        if time < 60
            return pluralize(time, 'minute')

        time /=60
        return pluralize(time, 'hour')


    startCountdown: (name, action) ->
        $phrase = @$el.find("[data-action='#{ name }'] .phrase")

        remaining = action.delay ? 3

        tick = =>
            remaining -= 1

            $phrase.text @renderPhrase(action, remaining)

            if remaining > 0
                @_timers[name] = setTimeout tick, 1000
            else
                delete @_timers[name]
                do action.action

        do tick

class Messenger
    OPT_DEFAULTS:
        type: 'info'

    constructor: (@$rootEl) ->
        @history = []

        do @render

    findById: (id) ->
        _.filter @history, (msg) ->
            msg.opts.id == id

    render: ->
        @$rootEl.html '<div class="messenger"></div>'

        @$el = @$rootEl.find('.messenger')

    _reserveMessageSlot: (msg) ->
        @history.push msg

        $slot = $('<div></div>')
        @$el.prepend $slot

        return $slot

    newMessage: (opts={}) ->
        msg = new MagicMessage(@, opts)
        msg.on 'show', =>
            do msg.scrollTo unless @$rootEl.css('position') is 'fixed'

        msg

    hideAll: ->
        for msg in @history
            msg.hide()

    post: (opts) ->
        if _.isString opts
            opts = {message: opts}

        opts = $.extend(true, {}, @OPT_DEFAULTS, opts)

        msg = @newMessage opts
        msg.update opts
        msg.show()
        return msg

class ActionMessenger extends Messenger
    ACTION_DEFAULTS:
        progressMessage: null
        successMessage: null
        errorMessage: "Error connecting to the server."

        showSuccessWithoutError: true

        retry:
            auto: true
            allow: true

        action: $.ajax

    hookBackboneAjax: (msgr_opts={}) ->

        msgr_opts = _.defaults msgr_opts,
            id: 'BACKBONE_ACTION'

            errorMessage: false
            successMessage: "Request completed successfully."

            showSuccessWithoutError: false

        _ajax = (opts) =>
            if $('html').hasClass('ie9-and-less')
                opts.cache = false

            @do msgr_opts, opts

        if Backbone.ajax?
            Backbone.ajax = _ajax
        else
            _old_sync = Backbone.sync
            Backbone.sync = (args...) ->
                _old_ajax = $.ajax
                $.ajax = _ajax

                _old_sync.call(Backbone, args...)

                $.ajax = _old_ajax

    _getMessage: (returnVal, def) ->
        if returnVal == false
            return false

        if returnVal == true or not returnVal? or typeof returnVal != 'string'
            return def

        return returnVal

    _parseEvents: (events={}) ->
        # We are extending the Backbone event syntax to allow a status to be included in event descriptions.
        # For example:
        #
        # 'success click': <some func>
        # 'error click a[href=#blah]': <some func>
        #
        out = {}
        for label, func of events
            firstSpace = label.indexOf ' '

            type = label.substring(0, firstSpace)
            desc = label.substring(firstSpace + 1)

            out[type] ?= {}
            # Due to how backbone expects events, it's not possible to have multiple callbacks bound to the
            # same event.
            out[type][desc] = func

        return out

    _normalizeResponse: (resp...) ->
        type = null
        xhr = null
        data = null

        for elem in resp
            if elem in ['success', 'timeout', 'abort']
                type = elem

            else if elem?.readyState? and elem?.responseText?
                xhr = elem

            else if _.isObject elem
                data = elem

        return [type, data, xhr]

    do: (m_opts, opts={}, args...) ->
        m_opts = $.extend true, {}, @ACTION_DEFAULTS, m_opts ? {}
        events = @_parseEvents m_opts.events

        if not m_opts.messageInstance and m_opts.id
            for m in @findById(m_opts.id)
                if m_opts.singleton
                    return false
                else
                    do m.hide

        msg = m_opts.messageInstance ? @newMessage m_opts

        if m_opts.id?
            msg.opts.id = m_opts.id

        if m_opts.progressMessage?
            msg.update $.extend {}, m_opts,
                message: m_opts.progressMessage
                type: 'info'

        _.each ['error', 'success'], (type) =>
            # Intercept the error and success handlers to give handle the messaging and give the client
            # the chance to stop or replace the message.
            #
            # - Call the existing handler
            #  - If it returns false, we don't show a message
            #  - If it returns anything other than false or a string, we show the default passed in for this type (e.g. successMessage)
            #  - If it returns a string, we show that as the message
            #

            old = opts[type] ? ->

            opts[type] = (resp...) =>

                [reason, data, xhr] = @_normalizeResponse(resp...)

                if type is 'success' and not msg.errorCount? and m_opts.showSuccessWithoutError == false
                    m_opts['successMessage'] = null

                if type is 'error'
                    msg.errorCount ?= 0
                    msg.errorCount += 1

                msgText = @_getMessage(r=old(resp...), m_opts[type + 'Message'])

                if type is 'error' and (xhr?.status == 0 or reason == 'abort')
                    # The request was aborted
                    do msg.hide
                    return

                if msgText
                    msgOpts = $.extend {}, m_opts,
                        message: msgText
                        type: type
                        events: events[type] ? {}

                        hideOnNavigate: type == 'success'


                    if type is 'error' and xhr?.status >= 500
                        if msgOpts.retry?.allow
                            if msgOpts.hideAfter
                              msgOpts.hideAfter += (msgOpts.retry.delay ? 10)

                            msgOpts._retryActions = true
                            msgOpts.actions =
                                retry:
                                    label: 'retry now'
                                    phrase: 'Retrying TIME'
                                    auto: msgOpts.retry.auto
                                    delay: msgOpts.retry.delay ? 10
                                    action: =>
                                        msgOpts.messageInstance = msg
                                        msgOpts.retry.delay = (msgOpts.retry.delay ? 10) * 2
                                        @do msgOpts, opts, args...
                                cancel:
                                    action: =>
                                        do msg.cancel

                    else if msgOpts._retryActions
                        delete m_opts.actions.retry
                        delete m_opts.actions.cancel
                        delete m_opts._retryActions

                    # Force the msg box to be rerendered if the page changed:
                    $.globalMessenger()

                    msg.update msgOpts
                    do msg.show

                else
                    do msg.hide

        msg._actionInstance = m_opts.action opts, args...

        return msg

$.fn.messenger = (func, args...) ->
    $el = this

    if not func?
        if not $el.data('messenger')?
            $el.data('messenger', new ActionMessenger($el))
            $._messengerInstance = $el.data('messenger')

        return $el.data('messenger')
    else
        return $el.data('messenger')[func](args...)

$.globalMessenger = (opts) ->
    inst = $._messengerInstance

    defaultOpts =
      injectIntoPage: false
      injectionLocations: ['.row-content', '.left', '.page', 'body']
      injectedClasses: 'injected-messenger'
      
      fixedClasses: 'fixed-messenger on-right'

    opts = $.extend defaultOpts, opts

    # Should we insert the messenger into the flow of the page, or
    # place it in the body to be position fixed or absolute.
    if opts.injectIntoPage
        locations = opts.injectionLocations
        $parent = null
        choosen_loc = null

        for loc in locations
            $parent = $(loc)

            if $parent.length
                chosen_loc = loc
                break

        if not inst
            $el = $('<div>')
            $el.addClass opts.injectedClasses

            $parent.prepend $el

            inst = $el.messenger()
            inst._location = chosen_loc

        else if $(inst._location) != $(chosen_loc)
            # A better location has since become avail on the page.

            inst.$el.detach()
            $parent.prepend inst.$el
    else
        if not inst
            $el = $('<div>')
            $el.addClass opts.fixedClasses

            $parent = $('body')
            $parent.append $el

            inst = $el.messenger()
            inst._location = $parent

    return inst
