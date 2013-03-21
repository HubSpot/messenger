1.3.0
-----

- Removed dependencies on Underscore and Backbone.
- Add src/js/shim.js which includes cutdown versions of some Underscore functions and Backbone's
  event handling.  It is included automatically in messenger.js and messenger.min.js.  This file 
  can be safely excluded in environments with Backbone and Underscore, but support for that is
  not yet in the build system.
- Add src/js/preboot.js which needs to be included before the main messenger file.  It is included
  automatically in messenger.js and messenger.min.js.

1.2.3
-----

- Internal references to Messenger will now function correctly when the Messenger object has
  been noConflicted.

1.2.2
-----

- Message strings (as opposed to full objects) can now be passed into message.update.

1.2.1
-----

- Added `ajax` alias for `run` with `$.ajax` as the action.  This is essentially identical
  to the default behavior, but is useful to those who wish to be more explicit.
- `message.retry.allow` can now be set to an integer representing the number of retries
  to be permitted.
- `message.retry.delay` now works as expected with non-integer delays.
- Bugfixes surrounding how `do`/`run` retries things.

1.2.0
-----

- Added global Messenger object which can be removed with `Messenger.noConflict()`.  The
  Messenger object will provide a container other than the jQuery object for messenger
  externals.
- `Messenger` may also be called to provide the same functionality as `$.globalMessenger`.
- Messenger default options may now be set on `window.Messenger.options` as well as
  `$._messengerDefaults`.
- The current instance of ActionMessenger which will be used by `Messenger()`/`$.globalMessenger`
  calls is now accessable as `window.Messenger.instance`, not `$._messengerInstance`.
- Added `run` alias for `do`.  This change makes it easier for developers writing js.
  In JavaScript, `do`, being a reserved word, always had to be referenced using array
  notation, this provides a way around that limitation.
- Created common way for themes to define extra JavaScript.  Themes can now define their
  own Messenger and/or Message objects in the `window.Messenger.themes.<theme_name>` object.
  If the theme name is provided in the options to globalMessenger as `options.theme`, the
  defined classes will be used.  As the theme now has to be passed in as a seperate option, the
  `messenger-theme-x` class will now be automatically added, and does not need to be
  provided in extraClasses.
- `MagicMessage` has been renamed `RetryingMessage`.
- The base classes `Message` and `Messenger` have been renamed `_Message` and `_Messenger` to
  signify that they are only for the internal structuring of the code, and not expected
  to be used directly.
- Messenger now exposes `ActionMessenger` (as `Messenger`) and `RetryingMessage` (as `Message`) for
  use by themes which wish to extend them.
