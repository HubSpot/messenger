coffee -o build/js src/coffee
coffee -o spec spec
cp src/coffee/*.js build/js

compass compile . --sass-dir "src/sass" --css-dir "build/css" --javascripts-dir "build/js" --images-dir "build/images"

echo "// Version `cat VERSION`\n// Built On `date`" | cat - build/js/messenger.js > tmp && mv tmp build/js/messenger.js
echo "// Version `cat VERSION`\n// Built On `date`" | cat - build/js/libs.js > tmp && mv tmp build/js/libs.js
