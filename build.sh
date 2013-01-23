handlebars src/handlebars/message.handlebars > build/js/templates/message.js
handlebars src/handlebars/messenger.handlebars > build/js/templates/messenger.js

coffee -o build/js src/coffee

sass --update src/sass:build/css
