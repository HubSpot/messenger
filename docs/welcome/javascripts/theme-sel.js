(function() {
  var ThemeSelector,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  ThemeSelector = (function(_super) {

    __extends(ThemeSelector, _super);

    function ThemeSelector() {
      return ThemeSelector.__super__.constructor.apply(this, arguments);
    }

    ThemeSelector.prototype.tagName = 'ul';

    ThemeSelector.prototype.className = 'theme-selector';

    ThemeSelector.prototype.events = {
      'click li': 'handleClick'
    };

    ThemeSelector.prototype.render = function() {
      var $li, theme, _i, _len, _ref, _results;
      this.$el.html('');
      _ref = this.options.themes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        theme = _ref[_i];
        $li = $('<li>');
        $li.attr('data-id', theme);
        $li.text(theme);
        _results.push(this.$el.append($li));
      }
      return _results;
    };

    ThemeSelector.prototype.handleClick = function(e) {
      var $li;
      $li = $(e.target);
      return this.trigger('update', $li.attr('data-id'));
    };

    return ThemeSelector;

  })(Backbone.View);

  $.fn.themeSelector = function(opts) {
    var sel;
    sel = new ThemeSelector($.extend({}, opts, {
      el: this
    }));
    $(this).addClass(sel.className);
    sel.render();
    return sel;
  };

}).call(this);
