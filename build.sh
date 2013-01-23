handlebars src/handlebars/message.handlebars > build/js/templates/message.js
handlebars src/handlebars/messenger.handlebars > build/js/templates/messenger.js

coffee -o build/js src/coffee

compass compile . --sass-dir "src/sass" --css-dir "build/css" --javascripts-dir "build/js" --images-dir "build/images"
