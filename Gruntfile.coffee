module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON("package.json")
    clean: ["build/js", "build/css"]

    concat:
      options:
        banner: "/*! <%= pkg.name %> <%= pkg.version %> */\n"

      dist:
        src: ["src/js/preboot.js", "lib/shims.js", "build/js/<%= pkg.name %>.js"]
        dest: "build/js/<%= pkg.name %>.js"

    uglify:
      options:
        banner: "/*! <%= pkg.name %> <%= pkg.version %> */\n"

      build:
        src: "build/js/<%= pkg.name %>.js"
        dest: "build/js/<%= pkg.name %>.min.js"

    coffee:
      options:
        separator: "/*! <%= pkg.name %> <%= pkg.version %> */\n"

      compile:
        files:
          "build/js/messenger.js": "src/coffee/messenger.coffee"
          "build/js/messenger-theme-future.js": "src/coffee/messenger-theme-future.coffee"
          "build/js/messenger-theme-flat.js": "src/coffee/messenger-theme-flat.coffee"

    compass:
      dist:
        options:
          sassDir: "src/sass"
          cssDir: "build/css"

  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-compass"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-concat"

  grunt.registerTask "default", ["clean", "coffee", "compass", "concat", "uglify"]
