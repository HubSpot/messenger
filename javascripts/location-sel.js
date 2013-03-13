(function() {
  var LocationSelector,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  LocationSelector = (function(_super) {

    __extends(LocationSelector, _super);

    function LocationSelector() {
      return LocationSelector.__super__.constructor.apply(this, arguments);
    }

    LocationSelector.prototype.className = 'location-selector';

    LocationSelector.prototype.events = {
      'click .bit': 'handleClick'
    };

    LocationSelector.prototype.render = function() {
      this.$el.html('');
      return this.draw();
    };

    LocationSelector.prototype.draw = function() {
      this._addBit('top left');
      this._addBit('top right');
      this._addBit('top');
      this._addBit('bottom left');
      this._addBit('bottom right');
      return this._addBit('bottom');
    };

    LocationSelector.prototype._addBit = function(classes) {
      var bit;
      bit = $('<div>');
      bit.addClass("bit " + classes);
      bit.attr('data-position', classes);
      this.$el.append(bit);
      return bit;
    };

    LocationSelector.prototype.handleClick = function(e) {
      var $bit;
      $bit = $(e.target);
      return this.trigger('update', $bit.attr('data-position').split(' '));
    };

    return LocationSelector;

  })(Backbone.View);

  $.fn.locationSelector = function(opts) {
    var loc;
    loc = new LocationSelector($.extend({}, opts, {
      el: this
    }));
    $(this).addClass(loc.className);
    loc.render();
    return loc;
  };

}).call(this);
