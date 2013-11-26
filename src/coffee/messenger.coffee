$ = jQuery
_ = window._ ? window.Messenger._
Events = Backbone?.Events ? window.Messenger.Events

# Emulates some Backbone-like eventing and element management for ease of use
# while attempting to avoid a hard dependency on Backbone itself
class BaseView
    constructor: (options) ->
        $.extend(@, Events)

        if _.isObject options
            if options.el
                @setElement(options.el)
            @model = options.model

        @initialize.apply(@, arguments)

    setElement: (el) ->
        @$el = $(el)
        @el = @$el[0]

    delegateEvents: (events) ->
        return unless events or (events = _.result(this, "events"))

        @undelegateEvents()

        delegateEventSplitter = /^(\S+)\s*(.*)$/

        for key of events
            method = events[key]
            method = this[events[key]]  unless _.isFunction(method)
            throw new Error("Method \"" + events[key] + "\" does not exist")  unless method
            match = key.match(delegateEventSplitter)

            eventName = match[1]
            selector = match[2]

            method = _.bind method, @
            eventName += ".delegateEvents#{@cid}"
            if selector == ''
                @jqon eventName, method
            else
                @jqon eventName, selector, method

    jqon: (eventName, selector, method) ->
        if @$el.on?
            @$el.on arguments...
        else
            # Support for jQuery > 1.7
            if not method?
                method = selector
                selector = undefined

            if selector?
                @$el.delegate selector, eventName, method
            else
                @$el.bind eventName, method

    jqoff: (eventName) ->
        if @$el.off?
            @$el.off arguments...
        else
            @$el.undelegate()
            @$el.unbind eventName
    
    undelegateEvents: () ->
        @jqoff ".delegateEvents#{this.cid}"

    remove: () ->
        @undelegateEvents()
        @$el.remove()

class _Message extends BaseView
    defaults:
        hideAfter: 10
        scroll: true

    initialize: (opts={}) ->
        @shown = false
        @rendered = false

        @messenger = opts.messenger

        @options = $.extend {}, @options, opts, @defaults

    show: ->
        unless @rendered
            do @render

        @$message.removeClass('messenger-hidden')

        wasShown = @shown
        @shown = true

        @trigger('show') unless wasShown

    hide: ->
        return unless @rendered

        @$message.addClass('messenger-hidden')

        wasShown = @shown
        @shown = false

        @trigger('hide') if wasShown

    cancel: ->
        do @hide

    update: (opts) ->
        if _.isString opts
            opts = {message: opts}

        $.extend(@options, opts)

        @lastUpdate = new Date()

        @rendered = false

        @events = @options.events ? {}

        do @render

        do @actionsToEvents
        do @delegateEvents

        do @checkClickable

        if @options.hideAfter
            @$message.addClass 'messenger-will-hide-after'

            if @_hideTimeout?
                clearTimeout @_hideTimeout

            @_hideTimeout = setTimeout =>
                do @hide
            , @options.hideAfter * 1000
        else
            @$message.removeClass 'messenger-will-hide-after'

        if @options.hideOnNavigate
            @$message.addClass 'messenger-will-hide-on-navigate'
            if Backbone?.history?
                Backbone.history.on 'route', =>
                    do @hide
        else
            @$message.removeClass 'messenger-will-hide-on-navigate'

        @trigger 'update', @

    scrollTo: ->
        return unless @options.scroll

        $.scrollTo @$el,
            duration: 400
            offset:
                left: 0
                top: -20

    timeSinceUpdate: ->
        return if @lastUpdate then ((new Date) - @lastUpdate) else null

    actionsToEvents: ->
        for name, act of @options.actions
            @events["click [data-action=\"#{ name }\"] a"] = ((act) =>
                return (e) =>
                    do e.preventDefault
                    do e.stopPropagation

                    @trigger "action:#{ name }", act, e
                    act.action.call @, e, @
            )(act)

    checkClickable: ->
        for name, evt of @events
            if name is 'click'
                @$message.addClass 'messenger-clickable'

    undelegateEvents: ->
        super

        @$message?.removeClass 'messenger-clickable'

    parseActions: ->
        actions = []

        for name, act of @options.actions
            n_act = $.extend {}, act
            n_act.name = name
            n_act.label ?= name

            actions.push n_act

        return actions

    template: (opts) ->
        $message = $ "<div class='messenger-message message alert #{ opts.type } message-#{ opts.type } alert-#{ opts.type }'>"

        if opts.showCloseButton
            $cancel = $ '<button type="button" class="messenger-close" data-dismiss="alert">&times;</button>'
            $cancel.click =>
              do @cancel

              true

            $message.append $cancel

        $text = $ """<div class="messenger-message-inner">#{ opts.message }</div>"""
        $message.append $text

        if opts.actions.length
            $actions = $ '<div class="messenger-actions">'

        for action in opts.actions
            $action = $ '<span>'
            $action.attr 'data-action', "#{ action.name }"

            $link = $ '<a>'
            $link.html action.label

            $action.append $ '<span class="messenger-phrase">'
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

        opts = $.extend {}, @options,
            actions: do @parseActions

        @$message = $ @template opts
        @$el.html @$message

        @shown = true
        @rendered = true

        @trigger 'render'

class RetryingMessage extends _Message
    initialize: ->
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

        @_timers = {}

        @$message?.removeClass 'messenger-retry-soon messenger-retry-later'

    render: ->
        super

        do @clearTimers

        for name, action of @options.actions
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
        if @_timers[name]?
            return

        $phrase = @$message.find("[data-action='#{ name }'] .messenger-phrase")

        remaining = action.delay ? 3

        if remaining <= 10
          @$message.removeClass 'messenger-retry-later'
          @$message.addClass 'messenger-retry-soon'
        else
          @$message.removeClass 'messenger-retry-soon'
          @$message.addClass 'messenger-retry-later'

        tick = =>
            $phrase.text @renderPhrase(action, remaining)

            if remaining > 0
                delta = Math.min(remaining, 1)
                remaining -= delta

                @_timers[name] = setTimeout tick, delta * 1000

            else
                @$message.removeClass 'messenger-retry-soon messenger-retry-later'
                delete @_timers[name]
                do action.action

        do tick

class _Messenger extends BaseView
    tagName: 'ul'
    className: 'messenger'

    messageDefaults:
        type: 'info'

    initialize: (@options={}) ->
        @history = []

        @messageDefaults = $.extend {}, @messageDefaults, @options.messageDefaults

    render: ->
        do @updateMessageSlotClasses

    findById: (id) ->
        _.filter @history, (rec) ->
            rec.msg.options.id == id

    _reserveMessageSlot: (msg) ->
        $slot = $('<li>')
        $slot.addClass 'messenger-message-slot'
        @$el.prepend $slot

        @history.push {msg, $slot}

        @_enforceIdConstraint msg
        msg.on 'update', => @_enforceIdConstraint(msg)

        while @options.maxMessages and @history.length > @options.maxMessages
          dmsg = @history.shift()
          dmsg.msg.remove()
          dmsg.$slot.remove()

        return $slot

    _enforceIdConstraint: (msg) ->
      return unless msg.options.id?

      for entry in @history
        _msg = entry.msg

        if _msg.options.id? and _msg.options.id is msg.options.id and msg isnt _msg
          if msg.options.singleton
            msg.hide()
            return
          else
            _msg.hide()

    newMessage: (opts={}) ->
        opts.messenger = @
        
        _Message = Messenger.themes[opts.theme ? @options.theme]?.Message ? RetryingMessage

        msg = new _Message(opts)

        msg.on 'show', =>
            if opts.scrollTo and @$el.css('position') isnt 'fixed'
                do msg.scrollTo

        msg.on 'hide show render', @updateMessageSlotClasses, @

        msg

    updateMessageSlotClasses: ->
        willBeFirst = true
        last = null

        anyShown = false

        for rec in @history
            rec.$slot.removeClass 'messenger-first messenger-last messenger-shown'

            if rec.msg.shown and rec.msg.rendered
                rec.$slot.addClass 'messenger-shown'
                anyShown = true

                last = rec
                if willBeFirst
                    willBeFirst = false
                    rec.$slot.addClass 'messenger-first'

        if last?
            last.$slot.addClass 'messenger-last'

        @$el["#{if anyShown then 'remove' else 'add'}Class"]('messenger-empty')

    hideAll: ->
        for rec in @history
            rec.msg.hide()

    post: (opts) ->
        if _.isString opts
            opts = {message: opts}

        opts = $.extend(true, {}, @messageDefaults, opts)

        msg = @newMessage opts
        msg.update opts
        return msg

class ActionMessenger extends _Messenger
    doDefaults:
        progressMessage: null
        successMessage: null
        errorMessage: "Error connecting to the server."

        showSuccessWithoutError: true

        retry:
            auto: true
            allow: true

        action: $.ajax

    # When called, will override Backbone.sync to place globalMessenger in the chain.
    # If using Backbone >= 0.9.9, will instead override Backbone.ajax
    hookBackboneAjax: (msgr_opts={}) ->
        if not window.Backbone?
            throw 'Expected Backbone to be defined'

        # Set backbone ajax defaults.
        msgr_opts = _.defaults msgr_opts,
            id: 'BACKBONE_ACTION'

            errorMessage: false
            successMessage: "Request completed successfully."

            showSuccessWithoutError: false

        # Create ajax override
        _ajax = (options) =>
            # if options were provided to this individual call, use them
            sync_msgr_opts = _.extend {}, msgr_opts, options.messenger

            @do sync_msgr_opts, options

        # If Backbone.ajax exists (Backbone >= 0.9.9), override it
        if Backbone.ajax?
            # We've already wrapped Backbone at some point.
            # Lets reverse that, so we don't end up making every request multiple times.
            if Backbone.ajax._withoutMessenger
                Backbone.ajax = Backbone.ajax._withoutMessenger

            # We set the action to Backbone.ajax so any previous overrides in Backbone.ajax are not clobbered
            # But we are careful not to override it if a different .action was passed in.
            if not msgr_opts.action? or msgr_opts.action is @doDefaults.action
                msgr_opts.action = Backbone.ajax

            # Keep a reference to the previous ajax
            _ajax._withoutMessenger = Backbone.ajax

            Backbone.ajax = _ajax
        # Override Backbone.sync if Backbone < 0.9.9
        else
            Backbone.sync = _.wrap Backbone.sync, (_old_sync, args...) ->
                # Switch ajax methods
                _old_ajax = $.ajax
                $.ajax = _ajax

                # Call old Backbone.sync (with it's original context)
                _old_sync.call(this, args...)

                # Restore ajax
                $.ajax = _old_ajax

    _getHandlerResponse: (returnVal) ->
        if returnVal == false
            return false

        if returnVal == true or not returnVal?
            return true

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

    run: (m_opts, opts={}, args...) ->
        m_opts = $.extend true, {}, @messageDefaults, @doDefaults, m_opts ? {}
        events = @_parseEvents m_opts.events

        getMessageText = (type, xhr) =>
            message = m_opts[type + 'Message']

            if _.isFunction message
              return message.call @, type, xhr
            return message

        msg = m_opts.messageInstance ? @newMessage m_opts

        if m_opts.id?
            msg.options.id = m_opts.id

        if m_opts.progressMessage?
            msg.update $.extend {}, m_opts,
                message: getMessageText('progress', null)
                type: 'info'

        handlers = {}
        _.each ['error', 'success'], (type) =>
            # Intercept the error and success handlers to give handle the messaging and give the client
            # the chance to stop or replace the message.
            #
            # - Call the existing handler
            #  - If it returns false, we don't show a message
            #  - If it returns anything other than false or a string, we show the default passed in for this type (e.g. successMessage)
            #  - If it returns a string, we show that as the message
            #
            originalHandler = opts[type]
            handlers[type] = (resp...) =>
                [reason, data, xhr] = @_normalizeResponse(resp...)

                if type is 'success' and not msg.errorCount? and m_opts.showSuccessWithoutError == false
                    m_opts['successMessage'] = null

                if type is 'error'
                    m_opts.errorCount ?= 0
                    m_opts.errorCount += 1

                # We allow message options to be returned by the original success/error handlers, or from the promise
                # used to call the handler.
                handlerResp = if m_opts.returnsPromise then resp[0] else originalHandler?(resp...)
                responseOpts = @_getHandlerResponse handlerResp
                if _.isString responseOpts
                    responseOpts = {message: responseOpts}

                if type is 'error' and (xhr?.status == 0 or reason == 'abort')
                    # The request was aborted
                    do msg.hide
                    return

                if type is 'error' and (m_opts.ignoredErrorCodes? and xhr?.status in m_opts.ignoredErrorCodes)
                    # We're ignoring this error
                    do msg.hide
                    return

                defaultOpts =
                    message: getMessageText(type, xhr)
                    type: type
                    events: events[type] ? {}

                    hideOnNavigate: type == 'success'

                msgOpts = $.extend {}, m_opts, defaultOpts, responseOpts

                if typeof msgOpts.retry?.allow is 'number'
                    msgOpts.retry.allow--

                if type is 'error' and xhr?.status >= 500 and msgOpts.retry?.allow
                    unless msgOpts.retry.delay?
                        if msgOpts.errorCount < 4
                            msgOpts.retry.delay = 10
                        else
                            msgOpts.retry.delay = 5 * 60

                    if msgOpts.hideAfter
                        msgOpts._hideAfter ?= msgOpts.hideAfter
                        msgOpts.hideAfter = msgOpts._hideAfter + msgOpts.retry.delay

                    msgOpts._retryActions = true
                    msgOpts.actions =
                        retry:
                            label: 'retry now'
                            phrase: 'Retrying TIME'
                            auto: msgOpts.retry.auto
                            delay: msgOpts.retry.delay
                            action: =>
                                msgOpts.messageInstance = msg

                                setTimeout =>
                                    @do msgOpts, opts, args...
                                , 0
                        cancel:
                            action: =>
                                do msg.cancel

                else if msgOpts._retryActions
                    delete msgOpts.actions.retry
                    delete msgOpts.actions.cancel
                    delete m_opts._retryActions

                msg.update msgOpts

                if responseOpts and msgOpts.message
                    # Force the msg box to be rerendered if the page changed:
                    Messenger()

                    do msg.show
                else
                    do msg.hide


        unless m_opts.returnsPromise
            for type, handler of handlers
                old = opts[type]
        
                opts[type] = handler

        msg._actionInstance = m_opts.action opts, args...

        if m_opts.returnsPromise
            msg._actionInstance.then(handlers.success, handlers.error)

        return msg
    
    # Aliases
    do: ActionMessenger::run
    ajax: (m_opts, args...) ->
        m_opts.action = $.ajax
    
        @run(m_opts, args...)

    expectPromise: (action, m_opts) ->
        m_opts = _.extend {}, m_opts,
            action: action
            returnsPromise: true

        @run(m_opts)

    error: (m_opts={}) ->
      if typeof m_opts is 'string'
        m_opts = {message: m_opts}

      m_opts.type = 'error'

      @post m_opts

    info: (m_opts={}) ->
      if typeof m_opts is 'string'
        m_opts = {message: m_opts}

      m_opts.type = 'info'

      @post m_opts

    success: (m_opts={}) ->
      if typeof m_opts is 'string'
        m_opts = {message: m_opts}

      m_opts.type = 'success'

      @post m_opts



$.fn.messenger = (func={}, args...) ->
    $el = this

    if not func? or not _.isString(func)
        opts = func

        if not $el.data('messenger')?
            _Messenger = Messenger.themes[opts.theme]?.Messenger ? ActionMessenger
            $el.data('messenger', instance = new _Messenger($.extend({el: $el}, opts)))
            instance.render()

        return $el.data('messenger')
    else
        return $el.data('messenger')[func](args...)

# When the object is created in preboot.coffee we see that this will be called
# when the object itself is called.
window.Messenger._call = (opts) ->

    defaultOpts =
        extraClasses: 'messenger-fixed messenger-on-bottom messenger-on-right'

        theme: 'future'
        maxMessages: 9
        parentLocations: ['body']

    opts = $.extend defaultOpts, $._messengerDefaults, Messenger.options, opts

    if opts.theme?
        opts.extraClasses += " messenger-theme-#{ opts.theme }"

    inst = opts.instance or Messenger.instance

    unless opts.instance?
        locations = opts.parentLocations
        $parent = null
        choosen_loc = null

        for loc in locations
            $parent = $(loc)

            if $parent.length
                chosen_loc = loc
                break

        if not inst
            $el = $('<ul>')

            $parent.prepend $el

            inst = $el.messenger(opts)
            inst._location = chosen_loc
            Messenger.instance = inst

        else if $(inst._location) != $(chosen_loc)
            # A better location has since become avail on the page.

            inst.$el.detach()
            $parent.prepend inst.$el

    if inst._addedClasses?
        inst.$el.removeClass inst._addedClasses

    inst.$el.addClass classes = "#{ inst.className } #{ opts.extraClasses }"
    inst._addedClasses = classes

    return inst

$.extend Messenger,
    Message: RetryingMessage
    Messenger: ActionMessenger
    
    themes: Messenger.themes ? {}

$.globalMessenger = window.Messenger = Messenger
