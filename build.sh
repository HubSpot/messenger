coffee -o build/js src/coffee

compass compile . --sass-dir "src/sass" --css-dir "build/css" --javascripts-dir "build/js" --images-dir "build/images"
