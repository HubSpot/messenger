class AnimationSelector extends Backbone.View
  ANIMATIONS: ['none', 'flash', 'shake', 'bounce', 'tada', 'swing', 'wobble', 'wiggle', 'pulse', 'flip', 'flipInX', 'flipOutX', 'flipInY', 'flipOutY', 'fadeIn', 'fadeInUp', 'fadeInDown', 'fadeInLeft', 'fadeInRight', 'fadeInUpBig', 'fadeInDownBig', 'fadeInLeftBig', 'fadeInRightBig', 'fadeOut', 'fadeOutUp', 'fadeOutDown', 'fadeOutLeft', 'fadeOutRight', 'fadeOutUpBig', 'fadeOutDownBig', 'fadeOutLeftBig', 'fadeOutRightBig', 'bounceIn', 'bounceInUp', 'bounceInDown', 'bounceInLeft', 'bounceInRight', 'bounceOut', 'bounceOutUp', 'bounceOutDown', 'bounceOutLeft', 'bounceOutRight', 'lightSpeedOut', 'hinge', 'rollIn', 'rollOut']

  events:
    'change select': 'handleChange'

  render: ->
    @$select = $ '<select>'
    @$el.html @$select

    for animation in @ANIMATIONS
      $item = $ '<option>'
      $item.text animation
      @$select.append $item

  handleChange: ->
    val = @$select.val()

    @trigger 'update', val

$.fn.animationSelector = (opts) ->
  sel = new AnimationSelector $.extend {}, opts,
    el: this

  sel.render()

  sel
