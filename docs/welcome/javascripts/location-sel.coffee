class LocationSelector extends Backbone.View
  className: 'location-selector'

  events:
    'click .bit': 'handleClick'

  render: ->
    @$el.html ''

    do @draw

  draw: ->
    @_addBit 'top left'
    @_addBit 'top right'
    @_addBit 'top'

    @_addBit 'bottom left'
    @_addBit 'bottom right'
    @_addBit 'bottom'

  _addBit: (classes) ->
    bit = $ '<div>'
    bit.addClass "bit #{ classes }"
    bit.attr 'data-position', classes
    @$el.append bit

    bit

  handleClick: (e) ->
    $bit = $ e.target

    @trigger 'update', $bit.attr('data-position').split(' ')

$.fn.locationSelector = (opts) ->
  loc = new LocationSelector $.extend {}, opts,
    el: this

  $(this).addClass loc.className
  loc.render()

  loc
