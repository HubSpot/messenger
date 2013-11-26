runners =
  'javascript': (opts, code) ->
      eval code

converters =
  'coffeescript:javascript': (opts, code) ->
    csOptions = $.extend {}, opts.coffeeOptions,
      bare: true

    CoffeeScript.compile code, csOptions


  'javascript:coffeescript': (opts, code) ->
    if Js2coffee
      out = Js2coffee.build code
    else
      #fallback if you dont include Js2Coffee
      console.error "Can't convert javascript to coffeescript"
      return code

normalizeType = (codeType) ->
  switch codeType.toLowerCase()
    when 'js', 'javascript', 'text/javascript', 'application/javascript'
      return 'javascript'
    when 'cs', 'coffee', 'coffeescript', 'text/coffeescript', 'application/coffeescript'
      return 'coffeescript'
    else
      console.error "Code type #{ codeType } not understood."

class Editor
  constructor: (args) ->
    @el = args.el
    @opts = args.opts
    @codeCache = {}

    @$el = $ @el

    do @buildEditor
    do @addRunButton
    do @addListeners

  getValue: ->
    @editor.getValue()

  addListeners: ->
    @$el.on 'executrSwitchType', (e, type) =>
      @switchType type

  addRunButton: ->
    @$runButton = $('<button>')
    @$runButton.addClass 'executr-run-button'
    @$runButton.text @opts.buttonText

    @$editorCont.append @$runButton

    @$runButton.css
      top: "#{ @$editorCont.height() / 2 - @$runButton.height() / 2 }px"

    if @$editorCont.height() < parseInt(@$runButton.css('font-size'), 10) + 4
      @$runButton.css 'font-size', "#{ @$editorCont.height() - 4 }px"

    @$runButton.click => do @execute

  buildEditor: ->
    @$editorCont = $('<div>')
    @$editorCont.addClass 'executr-code-editor'
    @$editorCont.css
      height: "#{ @$el.height() + 10 }px"
      width: "#{ @$el.width() }px"

    @$editorCont.insertBefore @$el
    @$el.detach()

    if typeof @opts.type is 'function'
      type = @opts.type(@$el, @)
    else
      type = @opts.type ? @$el.attr('data-type') ? @opts.defaultType

    type = normalizeType type

    code = @$el.text()

    mirrorOpts =
      value: code
      mode: type

    @codeCache[type] = code

    @editor = CodeMirror @$editorCont[0], $.extend(mirrorOpts, @opts.codeMirrorOptions)

    @editor.on('change', (doc, changeObj) =>
      if changeObj?.origin and not (changeObj.origin instanceof Object)
        @codeCache = {}
    )

  getType: ->
    @editor.getMode().name

  switchType: (type) ->
    type = normalizeType type
    currentType = @getType()

    if type is currentType
      return

    if @codeCache[type]
      code = @codeCache[type]
    else
      converter = converters["#{ currentType }:#{ type }"]

      unless converter?
        console.error "Can't convert #{ currentType } to #{ type }"
        return

      code = converter @opts, @editor.getValue()
      @codeCache[type] = code

    @editor.setOption 'mode', type
    @editor.setValue code
    @editor.refresh()

    scrollInfo = @editor.getScrollInfo()

    @$editorCont.css
      height: "#{ scrollInfo.height }px"

  # Do the actual runny bit.
  #
  # Also handles converting the source into a language we know how to run.
  run: (type, opts, code) ->
    runner = runners[type]

    # Non-recursivly (max depth == 1) try to convert the source
    # into a language we can run.
    unless runner?
      for key, func of converters
        [from, to] = key.split ':'

        if type is from and runners[to]
          runner = runners[to]
          code = func(opts, code)

    if not runner?
      console.error "Couldn't find a way to run #{ type } block"
      return

    runner opts, code

  execute: ->
    code = @getValue()
    codeType = @getType()

    @$el.trigger 'executrBeforeExecute', [code, codeType, @opts]
    if @opts.setUp?
      @opts.setUp(codeType, @opts)

    output = @run codeType, @opts, code

    if @opts.tearDown?
      @opts.tearDown(output, codeType, @opts)
    @$el.trigger 'executrAfterExecute', [output, code, codeType, @opts]

    insertOutput @opts, output


getCodeElement = (e, opts) ->
  $target = $ e.target
  $code = $target.parents(opts.codeSelector)

  if not $code.length and $target.is(opts.codeSelector)
    $code = $target

  $code

insertOutput = (opts, output) ->
  if opts.outputTo
    if opts.appendOutput
      $(opts.outputTo).append $('<div>').text(output)
    else
      $(opts.outputTo).text output

$.fn.executr = (opts) ->
  defaults =
    codeSelector: 'code[executable]'
    outputTo: false
    appendOutput: true
    defaultType: 'coffee'
    buttonText: "RUN"

  opts = $.extend {}, defaults, opts

  if this.is(opts.codeSelector)
    # Allow single code blocks to be passed in
    opts.codeSelector = null


  codeSelectors = this.find(opts.codeSelector)

  codeSelectors.each (i, el) ->
    new Editor({el: el, opts: opts})

  $('.executr-switch').click ->
    $this = $(@)
    $this.addClass('selected').siblings().removeClass('selected')
    codeType = $this.attr('data-code-type')
    codeSelectors.trigger 'executrSwitchType', codeType

