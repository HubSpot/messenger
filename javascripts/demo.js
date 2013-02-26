$(function(){
  $.globalMessenger().post("Thanks for checking out Messenger!");

  var loc = ['bottom', 'right'];
  var style = 'future';

  var $output = $('.controls output');

  var update = function(){
    classes = 'messenger-fixed';

    classes += ' messenger-theme-' + style;

    for (var i=0; i < loc.length; i++)
      classes += ' messenger-on-' + loc[i];

    $.globalMessenger({extraClasses: classes});
    $._messengerDefaults = {extraClasses: classes};

    $output.text("$._messengerDefaults = {\n\textraClasses: '" + classes + "'\n}")
  };

  update();

  $('.location-selector').locationSelector()
    .on('update', function(pos){
      loc = pos;

      update();
    });


  $('.theme-selector').themeSelector({
    themes: ['future', 'block']
  }).on('update', function(theme){
    style = theme;

    update();
  });


});
