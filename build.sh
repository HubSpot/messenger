coffee -o build/js src/coffee

compass compile . --sass-dir "src/sass" --css-dir "build/css" --javascripts-dir "build/js" --images-dir "build/images"

echo "// Version `cat VERSION`\n// Built On `date`" | cat - build/js/messenger.js > tmp && mv tmp build/js/messenger.js
