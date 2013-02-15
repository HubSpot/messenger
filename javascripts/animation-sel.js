(function() {
  var AnimationSelector,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  AnimationSelector = (function(_super) {

    __extends(AnimationSelector, _super);

    function AnimationSelector() {
      return AnimationSelector.__super__.constructor.apply(this, arguments);
    }

    AnimationSelector.prototype.ANIMATIONS = ['none', 'flash', 'shake', 'bounce', 'tada', 'swing', 'wobble', 'wiggle', 'pulse', 'flip', 'flipInX', 'flipOutX', 'flipInY', 'flipOutY', 'fadeIn', 'fadeInUp', 'fadeInDown', 'fadeInLeft', 'fadeInRight', 'fadeInUpBig', 'fadeInDownBig', 'fadeInLeftBig', 'fadeInRightBig', 'fadeOut', 'fadeOutUp', 'fadeOutDown', 'fadeOutLeft', 'fadeOutRight', 'fadeOutUpBig', 'fadeOutDownBig', 'fadeOutLeftBig', 'fadeOutRightBig', 'bounceIn', 'bounceInUp', 'bounceInDown', 'bounceInLeft', 'bounceInRight', 'bounceOut', 'bounceOutUp', 'bounceOutDown', 'bounceOutLeft', 'bounceOutRight', 'lightSpeedOut', 'hinge', 'rollIn', 'rollOut'];

    AnimationSelector.prototype.events = {
      'change select': 'handleChange'
    };

    AnimationSelector.prototype.render = function() {
      var $item, animation, _i, _len, _ref, _results;
      this.$select = $('<select>');
      this.$el.html(this.$select);
      _ref = this.ANIMATIONS;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        animation = _ref[_i];
        $item = $('<option>');
        $item.text(animation);
        _results.push(this.$select.append($item));
      }
      return _results;
    };

    AnimationSelector.prototype.handleChange = function() {
      var val;
      val = this.$select.val();
      return this.trigger('update', val);
    };

    return AnimationSelector;

  })(Backbone.View);

  $.fn.animationSelector = function(opts) {
    var sel;
    sel = new AnimationSelector($.extend({}, opts, {
      el: this
    }));
    sel.render();
    return sel;
  };

}).call(this);
