module.exports = function(grunt) {

grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),

    clean: ['build/js', 'build/css'],

    uglify: {
        options: {
            banner: '/*! <%= pkg.name %> <%= grunt.template.today("yyyy-mm-dd") %> */\n'
        },
        build: {
            src: 'build/js/<%= pkg.name %>.js',
            dest: 'build/js/<%= pkg.name %>.min.js'
        }
    },

    coffee: {
        compile: {
            files: {
                 "build/js/messenger.js": "src/coffee/messenger.coffee"
            }
        }
    },

    compass: {
        dist: {
            options: {
                sassDir: "src/sass",
                cssDir: "build/css"
            }
        }
    }

});

grunt.loadNpmTasks('grunt-contrib-uglify');
grunt.loadNpmTasks('grunt-contrib-compass');
grunt.loadNpmTasks('grunt-contrib-coffee');
grunt.loadNpmTasks('grunt-contrib-clean');

grunt.registerTask('default', ['clean', 'coffee', 'compass', 'uglify']);

};
