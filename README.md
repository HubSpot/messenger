Hubspot Messaging Library
=========================

Show transactional messages in your app.

Requires
--------

- jQuery
- Backbone.js
- jQuery.scrollTo.js - optionally

Plays well with bootstrap

Including
--------

### JS
    messenger/build/js/jquery.messenger.js

### CSS
    messenger/build/css/messenger.css

Really Quick Usage
-----

```coffeescript

# Replace:
$.ajax
    url: "/some-url"
    success: ->
    
# With:
$.globalMessenger().do
    errorMessage: "This did not go well."
,
    url: "/some-url"
    success: ->
    
```

Usage
-----

```coffeescript

$.globalMessenger().post "Your request has succeded!"

$.globalMessenger().post
    message: 'There was an explosion while processing your request.'
    type: 'error'

msg = $.globalMessenger().post "My Message"
msg.update "I changed my mind, this is my message"
msg.hide()

# Want to put actions at the end of your messages?
msg = $.globalMessenger().post
    message: 'Launching thermonuclear war...'
    type: 'info'
    actions:
        cancel:
            label: 'cancel launch'
            action: ->
                msg.update
                    message: 'Thermonuclear war averted'
                    type: 'success'

# Have an error? How about auto retrys with a Gmail-style countdown?:
msg = $.globalMessenger().post
    message: "I'm sorry Hal, I just can't do that."
    actions:
        retry:
            label: 'retry now'
            phrase: 'Retrying TIME'
            auto: true
            delay: 10
            action: ->
                # Do some retrying...

        cancel:
            action: ->
                do msg.cancel

# You can bind to action events as well:
msg.on 'action:retry', ->
    alert('Hey, you retried!')

# Need more control? You can bind events backbone-style based on the type of message.
msg.update
    events:
        'success click': ->
            # Will fire when the user clicks the message in a success state.
    
        'error click a.awesome-class': ->
            # Rock on

# Need your message to hide after a while, or when the Backbone router changes the page?
$.globalMessenger().post
    message: "Weeeeee"

    hideAfter: 10
    hideOnNavigate: true

# Don't want your message hidden on a long page? (Not necessary if you're using the default
# fixed positioning)
msg = $.globalMessenger().post
    message: "You'll see me!"
    
    scrollTo: true
    # Requires jQuery scrollTo plugin

msg.scrollTo() # also works

# Lazy/smart? How about messenger does it all for you?  All the retry magic comes with.
$.globalMessenger().do
    successMessage: 'Data saved.'
    errorMessage: 'Error saving data'
    progressMessage: 'Saving data' # Don't include messages you don't want to appear.

    # Any standard message opts can go here
,
    # All the standard jQuery ajax options here

    url: '/data'

# Need to override the messages based on the response?
$.globalMessenger().do
    errorMessage: 'Oops'
,
    url: '/data'
    error: (xhr) ->
        # Whatever you return from your handlers will replace the default messages

        if xhr?.status is 404
            return "Data not found"
        
        # Return true or undefined for your predefined message
        # Return false to not show any message

        return true

# Sometimes you only want to show the success message when a retry succeeds, not if a retry wasen't required:
$.globalMessenger().do
    successMessage: 'Successfully saved.'
    errorMessage: 'Error saving'

    showSuccessWithoutError: false
,
    url: '/data'

# You don't have to use $.ajax as your action, messenger works great for any async process:
$.globalMessenger().do
    successMessage: 'Bomb defused successfully'

    action: defuseBomb
,
    # You can put options for defuseBomb here
    # It will be passed success and error callbacks

# Need to hide all messages?
$.globalMessenger().hideAll()

# Do you use Backbone? Hook all backbone calls:
$.globalMessenger().hookBackboneAjax()

# You don't have to use the global messenger
$('div#message-container').messenger().post "My message"

# By default, the global messenger will create an ActionMessenger instance fixed to the bottom-right
# corner of the screen.  If there is already a messenger instance on the page, it will use that one.

# Alternativly, pass {injectIntoPage: true} to globalMessenger to have a messenger instance injected into the page in a few likely
# places.  This will only work if an instance has not yet been created.

$.globalMessenger({injectIntoPage: true})

# All the options for globalMessenger and their defaults:

{
  'injectIntoPage': false,
  'fixedMessageClasses': 'hs-fixed-message-box',
  'injectedMessageClasses': 'hs-message-box',
  'injectionLocations': ['.row-content', '.left', '.page', 'body']
}

# You can also use the views directly
messenger = new ActionMessenger $('div#message-container')
messenger.post "Yay!!!"

```

Contributing
==========

You can build the output files by running `build.sh`.  It requires coffeescript, sass and handlebars.
