$ = jQuery

spinner_template = '''
    <div class="messenger-spinner">
        <span class="messenger-spinner-side messenger-spinner-side-left">
            <span class="messenger-spinner-fill"></span>
        </span>
        <span class="messenger-spinner-side messenger-spinner-side-right">
            <span class="messenger-spinner-fill"></span>
        </span>
    </div>
'''

class Message extends Backbone.View
    defaults:
        hideAfter: 10
        scroll: true

    initialize: (opts={}) ->
        @shown = false
        @rendered = false

        @messenger = opts.messenger

        @options = $.extend {}, @options, opts, @defaults

    show: ->
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
            if Backbone.history?
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
            @events["click [data-action=\"#{ name }\"] a"] = ((act) ->
                return (e) =>
                    do e.preventDefault
                    do e.stopPropagation

                    act.action(e)
            )(act)

    checkClickable: ->
        for name, evt of @events
            if name is 'click'
                @$messenger.addClass 'messenger-clickable'

    undelegateEvents: ->
        super

        @$messenger?.removeClass 'messenger-clickable'

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
            $cancel = $ '<button type="button" class="close" data-dismiss="alert">&times;</button>'
            $cancel.click =>
              do @cancel

              true

            $message.append $cancel

        $text = $ """<div class="messenger-message-inner">#{ opts.message }</div>"""
        $message.append $text

        $message.append $ spinner_template

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

        if @_addedClasses?
          @$el.removeClass @_addedClasses
          @_addedClasses = null

        if opts.extraClasses?
          @$el.addClass opts.extraClasses
          @_addedClasses = opts.extraClasses

        @shown = true
        @rendered = true

        @trigger 'render'

class MagicMessage extends Message
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
        $phrase = @$message.find("[data-action='#{ name }'] .messenger-phrase")

        remaining = action.delay ? 3

        if remaining <= 10
          @$message.removeClass 'messenger-retry-later'
          @$message.addClass 'messenger-retry-soon'
        else
          @$message.removeClass 'messenger-retry-soon'
          @$message.addClass 'messenger-retry-later'

        tick = =>
            remaining -= 1

            $phrase.text @renderPhrase(action, remaining)

            if remaining > 0
                @_timers[name] = setTimeout tick, 1000
            else
                @$message.removeClass 'messenger-retry-soon messenger-retry-later'
                delete @_timers[name]
                do action.action

        do tick

class Messenger extends Backbone.View
    tagName: 'ul'
    className: 'messenger'

    OPT_DEFAULTS:
        type: 'info'

    initialize: (@options) ->
        @history = []

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
        msg = new MagicMessage(opts)

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
            rec.$slot.removeClass 'first last shown'

            if rec.msg.shown and rec.msg.rendered
                rec.$slot.addClass 'shown'
                anyShown = true

                last = rec
                if willBeFirst
                    willBeFirst = false
                    rec.$slot.addClass 'first'

        if last?
            last.$slot.addClass 'last'

        @$el["#{if anyShown then 'remove' else 'add'}Class"]('messenger-empty')

    hideAll: ->
        for rec in @history
            rec.msg.hide()

    post: (opts) ->
        if _.isString opts
            opts = {message: opts}

        opts = $.extend(true, {}, @OPT_DEFAULTS, opts)

        msg = @newMessage opts
        msg.update opts
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
            Backbone.sync = (method, model, options) ->
                _old_ajax = $.ajax
                $.ajax = _ajax

                if options.messenger?
                    _.extend msgr_opts, options.messenger

                _old_sync.call(Backbone, method, model, options)

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

        msg = m_opts.messageInstance ? @newMessage m_opts

        if m_opts.id?
            msg.options.id = m_opts.id

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
                    m_opts.errorCount ?= 0
                    m_opts.errorCount += 1

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

        promiseAttrs = ['done', 'progress', 'fail', 'state', 'then']
        for attr in promiseAttrs
          delete msg[attr] if msg[attr]?
          msg[attr] = msg._actionInstance?[attr]

        return msg

$.fn.messenger = (func={}, args...) ->
    $el = this

    if not func? or not _.isString(func)
        opts = func

        if not $el.data('messenger')?
            $el.data('messenger', instance = new ActionMessenger($.extend({el: $el}, opts)))
            instance.render()

        return $el.data('messenger')
    else
        return $el.data('messenger')[func](args...)

$.globalMessenger = (opts) ->

    defaultOpts =
        extraClasses: 'messenger-fixed messenger-on-bottom messenger-on-right messenger-theme-future'

        maxMessages: 9
        parentLocations: ['body']

    opts = $.extend defaultOpts, $._messengerDefaults, opts

    inst = opts.instance or $._messengerInstance
    
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
            $._messengerInstance = inst
    
        else if $(inst._location) != $(chosen_loc)
            # A better location has since become avail on the page.
    
            inst.$el.detach()
            $parent.prepend inst.$el

    if inst._addedClasses?
        inst.$el.removeClass inst._addedClasses

    inst.$el.addClass classes = "#{ inst.className } #{ opts.extraClasses }"
    inst._addedClasses = classes

    return inst
