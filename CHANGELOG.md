1.2.0
-----

Added global Messenger object which can be removed with `Messenger.noConflict()`.  The
Messenger object will provide a container other than the jQuery object for messenger
externals.

Messenger may also be called to provide the same functionality as `$.globalMessenger`.

Messenger default options may now be set on `window.Messenger.options` as well as
`$._messengerDefaults`.

The current instance of ActionMessenger which will be used by Messenger()/$.globalMessenger
calls is now accessable as `window.Messenger.instance`, not `$._messengerInstance`.

Added `run` alias for `go`.  This change makes it easier for developers writing js. 
In JavaScript, go, being a reserved word, always had to be referenced using array
notation, this provides a way around that limitation.

Created common way for themes to define extra JavaScript.  Themes can now define their
own Messenger and/or Message objects in the `window.Messenger.themes.<theme_name>` object.
If the theme name is provided in the options to globalMessenger as `options.theme`, the 
defined classes will be used.  As the theme now has to be passed in as a seperate option, the
`messenger-theme-x` class will now be automatically added, and does not need to be
provided in extraClasses.

MagicMessage has been renamed RetryingMessage.

The base classes Message and Messenger have been renamed _Message and _Messenger to
signify that they are only for the internal structuring of the code, and not expected
to be used directly.

Messenger now exposes ActionMessenger (as Messenger) and RetryingMessage (as Message) for
use by theme which wish to extend them.
