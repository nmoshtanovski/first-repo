var grunt = require('grunt');

grunt.loadNpmTasks('grunt-aws-lambda');

grunt.initConfig({
    lambda_invoke: {
        default: {
            options: {
                file_name: 'index.js'
            }
        },
        greetings: {
            options: {
                file_name: 'Greetings.js'
            }
        }
    },
    lambda_deploy: {
        default: {
            arn: 'DefaultLambdaFunction',

            options: {
                timeout: 60,
                memory: 128
              }
        },
        greetings: {
            arn: 'TestGreetings',

            options: {
                file_name: 'Greetings.js',
                timeout: 60,
                memory: 128
              }
        }
    },
    lambda_package: {
        default: {},
        greetings: {
            options: {
              include_time: false,
              include_version: false
            }
        }
    }
});

grunt.registerTask('deploy', ['lambda_package', 'lambda_deploy'])

grunt.registerTask('deploy_greetings', ['lambda_package:greetings', 'lambda_deploy:greetings'])
