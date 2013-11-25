# Messenger

#### [Demo and Usage](http://hubspot.github.com/messenger/docs/welcome)

- Show messages in your app.
- Wrap AJAX requests with progress, success and error messages, and add retry to your failed requests.
- Add actions (undo, cancel, etc.) to your messages.

![Messenger](https://raw.github.com/HubSpot/messenger/master/promotional-images/messenger.gif)

Messenger is different from other solutions for a few reasons:

- Each message can be updated after being posted without losing it's place
- Actions and events can be bound to messages
- It's completely themeable with CSS
- A 'tray' element exists to allow you to style the box around the messages, and limit the number
of messages on the screen

### Messenger Object

Messenger is accessed through a global `Messenger` object.  The object is called at each usage to give
it a chance to instantiate if necessary: `Messenger()`.

The most basic usage is to post a message:

`Messenger().post({ options })` - Show a message

Options can be a string representing the body of the message:

```javascript
Messenger().post("Welcome to the darkside (tm)")
```

It can also be an object:

```javascript
Messenger().post({
  message: "How's it going?"
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

The object provided by `Messenger()` also has a couple of additional methods:

- `hideAll`: Hide all messages
- `run`: See 'Running Things` below
- `ajax`: See 'Running Things` below
- `expectPromise`: See 'Running Things` below
- `hookBackboneAjax`: See Backbone below

