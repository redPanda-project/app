pipeline {
    agent {
        docker {
            image 'cirrusci/flutter'
            args '-u root'
        }
    }
    stages {
        stage ('Prepare lcov converter') {
            steps {
                sh "curl -O https://raw.githubusercontent.com/eriwen/lcov-to-cobertura-xml/master/lcov_cobertura/lcov_cobertura.py"
                sh 'apt-get update'
                sh 'apt-get -y install python3-pip'
                sh 'python3 -m pip install setuptools'
            }
        }
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
                    sh "python3 lcov_cobertura.py coverage/lcov.info --output coverage/coverage.xml"
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
    }
}