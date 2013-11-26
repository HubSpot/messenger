## executr

Let your users execute and play with the CoffeeScript and JavaScript in your documentation

### Example

See our messenger documentation for an example: http://hubspot.github.com/messenger/

### Including

````html
<!-- You should already have jQuery included -->

<!-- Code Mirror is used to make the code blocks editable -->
<script type="text/javascript" src="lib/CodeMirror/codemirror.js"></script>

<!-- Include the CodeMirror languages you're going to use -->
<script type="text/javascript" src="lib/CodeMirror/mode/coffeescript/coffeescript.js"></script>
<script type="text/javascript" src="lib/coffee-script.js"></script>

<script type="text/javascript" src="build/js/executr.js"></script>

<link rel="stylesheet" type="text/css" media="screen" href="lib/CodeMirror/codemirror.css">
<link rel="stylesheet" type="text/css" media="screen" href="build/css/executr.css">
````

### Usage

The code blocks you wish to be executable should be wrapped in `<code executable></code>`.

Run `$.executr` on the container of multiple code elements, the body, or a single code block.

The blocks will be converted into CodeMirror Editors, and a run button will be added.  If you're not interested
in the code being editable, take a look at the v1.1 tag.

Only the text (not tags) in the block will be executed, feel free to wrap your already-syntax-highlighted code.

The code editor will assume the height + 10px and width of the code element.

````html
<pre><code executable>
$ ->
  alert "Testing!"
</code></pre>
````

````javascript
$(function(){
  $('body').executr();
});
````

You can also make javascript executable, by either adding a `data-type="javascript"` attribute to the code
block, or by adding `defaultType: 'javascript'` to the executr call.

````html
<code data-type="javascript" executable>
alert("Testing!");
</code>
````

### Other Options

$.executr can be passed the following options

````coffeescript
{
    codeSelector: 'code[executable]' # The jQuery selector items to be bound must match

    outputTo: 'div.output' # An element which should receive the output.
    appendOutput: true # Whether output should replace the contents of outputTo, or append to it

    defaultType: 'coffeescript' # The default source languange, if not supplied as a data-type attribute
    type: 'coffeescript' # The type to force on all code blocks, even if otherwise specified.  Can also be a function.
    coffeeOptions: {} # Extra options for the CoffeeScript compiler

    codeMirrorOptions: {} # Extra options for CodeMirror

    setUp: -> # Code to run before each code block
    tearDown: -> # Code to run after each code block
}
````

#### Events

Executr will fire two events on the element it is bound to:

- `executrBeforeExecute(code string, normalized code language, executr options)`
- `executrAfterExecute(code output, code string, normalized code language, executr options)`

#### Contributing

You can build the project by running `./build.sh`.  It requires the CoffeeScript compiler.
