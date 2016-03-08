<script type="text/javascript" src="build/js/messenger.js"></script>
<script type="text/javascript" src="build/js/messenger-theme-future.js"></script>
<link rel="stylesheet" type="text/css" media="screen" href="build/css/messenger.css">
<link rel="stylesheet" type="text/css" media="screen" href="build/css/messenger-theme-future.css">

# Messenger

#### [Demo and Usage](http://hubspot.github.com/messenger/docs/welcome)

- Show messages in your app.
- Wrap AJAX requests with progress, success and error messages, and add retry to your failed requests.
- Add actions (undo, cancel, etc.) to your messages.

Messenger is different from other solutions for a few reasons:

- Each message can be updated after being posted without losing it's place
- Actions and events can be bound to messages
- It's completely themeable with CSS
- A 'tray' element exists to allow you to style the box around the messages, and limit the number
of messages on the screen

### Messenger Object

Messenger is accessed through a global `Messenger` object.  The object is called at each usage to give
it a chance to instantiate if necessary.

The most basic usage is to post a message:

```javascript
Messenger().post({ options })
```

Options can be a string representing the body of the message:

```javascript
Messenger().post("Welcome to the darkside (tm)")
```

It can also be an object:

```javascript
Messenger().post({
  message: "How's it going?",
  type: "error"
})
```

The full list of options:

- `message`: The text of the message
- `type`: `info`, `error` or `success` are understood by the provided themes. You can also pass your
own string, and that class will be added.
- `theme`: What theme class should be applied to the message? Defaults to the theme set for Messenger in
general.
- `id`: A unique id.  If supplied, only one message with that ID will be shown at a time.
- `singleton`: Hide the newer message if there is an `id` collision, as opposed to the older message.
- `actions`: Action links to put in the message, see the 'Actions' section on this page.
- `hideAfter`: Hide the message after the provided number of seconds
- `hideOnNavigate`: Hide the message if Backbone client-side navigation occurs
- `showCloseButton`: Should a close button be added to the message?
- `closeButtonText`: Specify the text the close button should use (default: &times;)
- `escapeText`: Should messenger escape message text? (default: false)
- `onClickClose`: Function that executes when the close button is clicked

Messenger also includes aliases which set the `type` for you: `Messenger().error()`, `Messenger().success()`, and `Messenger().info()`.

### Updating Messages

Rather than posting a new message when progress occurs, it can be nice to update an existing message.

`.post`, along with the other message posting methods, provide a `Message` instance which has the
following methods:

- `show()`: Show the message, if it's hidden
- `hide()`: Hide the message, if it's shown
- `cancel()`: If the message is associated with an ajax request or is counting down to retry, cancel it
- `update({ options })`: Update the message with the provided options

Any option, such as `type` or `message` can be changed with `update`:

```javascript
message = Messenger().post("Calculating position")
message.update({
  type: "error",
  message: "Error calculating position"
})
```

### Messenger Object

When `Messenger` is called, it creates, if necessary, a container for future messages to be placed into.
`Messenger` can be passed options to configure the container when it's first called, future calls will
alter the existing container.

`Messenger` options:

- `extraClasses`: Extra classes to be appended to the container.  These can be used to configure the active theme.
If you'd like the messenger box to be overlayed on the screen, you should provide the `messenger-fixed` class along with any of
the following positioning classes: `messenger-on-bottom`, `messenger-on-top`, `messenger-on-left`, `messenger-on-right`.
Adding the `top` or `bottom` class along with a `left` or `right` will move the messenger dialog into the specified corner.
- `maxMessages`: The maximum number of messages to show at once
- `parentLocations`: Which locations should be tried when inserting the message container into the page.  The default is `['body']`.
It accepts a list to allow you to try a variety of places when deciding what the optimal location is on any given page.  This should
generally not need to be changed unless you are inserting the messages into the flow of the document, rather than using `messenger-fixed`.
- `theme`: What theme are you using? Some themes have associated javascript, specifing this allows that js to run.
- `messageDefaults`: Default options for created messages

```javascript
Messenger({
  parentLocations: ['.page'], // Let's insert it into the page
  extraClasses: ''            // And not add the fixed classes
})

// Future calls just need to refer to Messenger(), they'll get the same instance
```

```javascript
Messenger({
  // Let's put the messenger in the top left corner
  extraClasses: 'messenger-fixed messenger-on-left messenger-on-top'
});
```

The object provided by `Messenger()` also has a couple of additional methods:

- `hideAll`: Hide all messages
- `run`: See 'Running Things' below
- `ajax`: See 'Running Things' below
- `expectPromise`: See 'Running Things' below
- `hookBackboneAjax`: See Backbone below

### Running Things

One of the most common use cases for messenger is to show the progress and success or error of an asynchronous action, like an ajax request.
Messenger includes a method to help with that, `run`.

`run({ messageOptions }, { actionOptions })`

messageOptions:

- `action`: The function which should be passed `actionOptions`.  `success` and `error` callbacks will be added to `actionOptions`
and used to show the appropriate messages.
- `successMessage`: What message should be shown if the action is a success?  Can be a string, or false if no message should be shown.  Can also
be a function returning a string, message options object, or false.
- `errorMessage`: Same as success message, but shown after the `error` callback is called.
- `progressMessage`: A message to be shown while the action is underway, or false.
- `showSuccessWithoutError`: Set to false if you only want the success message to be shown if the success comes after a failure
- `ignoredErrorCodes`: By default the error handler looks for `xhr.status`, assuming the action is $.ajax.  If it is, this can be set to an
array of HTTP status codes which should _not_ be considered an error.
- `returnsPromise`: If true, instead of wrapping the `success` and `error` callbacks passed to `action`, we expect `action` to return to
us a promise, and use that to show the appropriate messages.
- `retry`: Set to false to not have the action retried if it fails.  Or set it to an object with the following options:
  - `allow`: Should we show a manual 'Retry' button?
  - `auto`: Should we automatically start the retry timer after a failure?
- Any other message options

Your success and error handlers can return false if they don't wish the message to be shown.  They can also return a string to change the
message, or an object to change more message options.

```javascript
Messenger().run({
  action: $.ajax,

  successMessage: 'Contact saved',
  errorMessage: 'Error saving contact',
  progressMessage: 'Saving contact...'
}, {
  /* These options are provided to $.ajax, with success and error wrapped */
  url: '/contact',
  data: contact,

  error: function(resp){
    if (resp.status === 409)
      return "A contact with that email already exists";
  }
});
```

We also provide a couple of aliases:

- `Messenger().ajax({ messageOptions }, { actionOptions })`:  Call `run` with `$.ajax` as the action (which is already the default).
- `Messenger().expectPromise(action, { messageOptions })`: Call `run` with a function which returns a promise, so actionOptions aren't necessary.

```javascript
Messenger().expectPromise(function(){
  return $.ajax({
    url: '/aliens/44',
    type: 'DELETE'
  });
}, {
  successMessage: 'Alien Destroyed!',
  progressMessage: false
});
```

All three methods return a `Message` instance.  You can call `message.cancel()` to stop the retrying, if necessary.

### Actions

You can pass messages a hash of actions the user can execute on the message.  For example, `run` will add 'Retry' and 'Cancel'
buttons to error messages which have retry enabled.

Actions are provided as the `actions` hash to `post` or `run`:

```javascript
msg = Messenger().post({
  message: "Are you sure you'd like to delete this contact?",

  actions: {
    delete: {
      label: "Delete",
      action: function(){
        delete()
        msg.hide()
      }
    },

    cancel: {
      action: function(){
        msg.hide()
      }
    }
  }
})
```

### Events

You can add DOM event handlers to the message itself, or any element within it.  For example, you might wish to do
something when the user clicks on the message.

The format of the event key is: "`[type] event [selector]`"

Type is a message type, like `success`, `error`, or `info`, or skip to ignore the type.  It's useful with `run` where
the same options are getting applied to the `success` and `error` messages.
Event is the DOM event to bind to.
Selector is any jQuery selector, or skip to bind to the message element itsef.

```javascript
Messenger().post({
  message: "Click me to explode!",

  events: {
    "click": function(e){
      explode();
    },
    "hover a.button": function(e){
      e.stopPropagation();
    }
  }
});
```

### Backbone.js

Messenger includes a function to hook into Backbone.js' sync method.  To enable it, call `Messenger().hookBackboneAjax({ defaultOptions })`
before making any Backbone requests (but after bringing in the Backbone.js js file).

You can pass it any default message options you would like to apply to your requests.  You can also set those options as `messenger` in
your save and fetch calls.

```javascript
Messenger().hookBackboneAjax({
  errorMessage: 'Error syncing with the server',
  retry: false
});

// Later on:
myModel.save({
  errorMessage: 'Error saving contact'
});
```

### Classes

Each message can have the following classes:

- `messenger-hidden` (message): Applied when a message is hidden
- `messenger-will-hide-after` (message): Applied if the `hideAfter` option is not false
- `messenger-will-hide-on-navigate` (message): Applied if the `hideOnNavigate` option is not false
- `messenger-clickable` (message): Applied if a 'click' event is included in the events hash
- `messenger-message` (message): Applied to all messages
- `messenger-{type}` (message): Applied based on the message's `type` (usually 'success', 'error', or 'info')
- `message`, `alert`, `alert-{type}` (message): Added for compatiblity with external CSS
- `messenger-retry-soon` (message): Added when the next retry will occur in less than or equal to 10s
- `messenger-retry-later` (message): Added when the next retry will occur in greater than 10s (usually 5min)

Every message lives in a slot, which is a li in the list of all the messages which have been created:

- `messenger-first` (slot): Added when this slot is the first shown slot in the list
- `messenger-last` (slot): Added when this slot is the last shown slot in the list
- `messenger-shown` (slot): Added when this slot is visible

All the slots are in a tray element:

- `messenger-empty` (tray): Added when there are no visible messages
- `messenger-theme-{theme}` (tray): Added based on the passed in `theme` option

### Multiple Messenger Trays

You can have multiple messenger trays on the page at the same time.  Manually create them using the
jQuery method:

```javascript
instance = $('.myContainer').messenger();
```

You can then pass your instance into the messenger methods:

```javascript
Messenger({instance: instance}).post("My awesome message")
```

### Contributing

The build process requires nodejs and grunt-cli.
You can build the output files by running `grunt`.
The automated tests can be run by opening SpecRunner.html in a browser.
