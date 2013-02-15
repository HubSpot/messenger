$(function(){
  $.globalMessenger().post("Thanks for checking out Messenger!");

  var loc = ['bottom', 'right'];
  var style = 'future';
  var messageAni = 'none';
  var containerAni = 'none';

  var update = function(){
    classes = 'messenger-fixed';

    classes += ' messenger-theme-' + style;

    for (var i=0; i < loc.length; i++)
      classes += ' messenger-on-' + loc[i];

    classes += ' animated ' + containerAni;

    // Change future messengers
    $._messengerDefaults = {extraClasses: classes, messageDefaults: {extraClasses: 'animated ' + messageAni}};

    // Change already rendered messenger
    $.globalMessenger({extraClasses: classes});
    $.extend($.globalMessenger().messageDefaults, {'extraClasses': 'animated ' + messageAni})
  };

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

  $('.container-animation-selector').animationSelector()
    .on('update', function(ani){
      containerAni = ani;

      update();
    });

  $('.message-animation-selector').animationSelector()
    .on('update', function(ani){
      messageAni = ani;

      update();
    });


});
