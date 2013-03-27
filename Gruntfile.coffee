module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    meta:
      banner: "/*! <%= pkg.name %> <%= pkg.version %> <%= grunt.template.today(\"yyyy-mm-dd\") %> */\n"

    clean: ["build/js", "build/css"]

    concat:
      options:
        banner: "<%= meta.banner %>"
      dist:
        src: ["src/js/preboot.js", "lib/shims.js", "build/js/<%= pkg.name %>.js"]
        dest: "build/js/<%= pkg.name %>.js"

    uglify:
      options:
        banner: "<%= meta.banner %>"
      build:
        src: "build/js/<%= pkg.name %>.js"
        dest: "build/js/<%= pkg.name %>.min.js"

    coffee:
      options:
        separator: "<%= meta.banner %>"
      compile:
        files:
          "build/js/messenger.js": "src/coffee/messenger.coffee"
          "build/js/messenger-theme-future.js": "src/coffee/messenger-theme-future.coffee"

    compass:
      dist:
        options:
          sassDir: "src/sass"
          cssDir: "build/css"

    jasmine:
      pivotal:
        src: ["lib/sinon-1.6.0.js", "spec/lib/jquery-1.9.1.js", "build/js/<%= pkg.name%>.js"]
        options:
          specs: "spec/*Spec.js",
          helpers: "spec/*Helper.js"

    watch:
      files: ["**/*.coffee", "!**/*.js", "!**/*.css"]
      tasks: ["default", "test"]

  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-compass"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-watch"

  grunt.registerTask "default", ["clean", "coffee", "compass", "concat", "uglify"]
  grunt.registerTask "test", ["jasmine"]
