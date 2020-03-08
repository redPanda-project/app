pipeline {
    agent {
        docker {
            image 'py4x3g/flutter_lcov_to_cobertura'
            args '-u root -v androidSDKvol:/opt/android-sdk-linux/ -v androidDir:/root/.android/'
        }
    }
    stages {
        stage ('Flutter Doctor') {
            steps {
                sh "flutter doctor"
            }
        }
        stage ('Flutter get') {
            steps {
                sh 'flutter pub get'
            }
        }
        stage('Test') {
            steps {
                sh "flutter test --coverage"
            }
            post {
                always {
                    sh "python3 /usr/bin/lcov_cobertura.py coverage/lcov.info --output coverage/coverage.xml"
                    step([$class: 'CoberturaPublisher', coberturaReportFile: 'coverage/coverage.xml'])
                }
            }
        }
        stage('Run Analyzer') {
            steps {
                //sh "dartanalyzer --options analysis_options.yaml ."
                sh 'dartanalyzer .'
            }
        }
        stage('Build Apk') {
            steps {
                sh 'flutter build apk'
            }
        }
    }
}