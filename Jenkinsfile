pipeline {
    agent any
    
    tools {
        maven 'Maven3'
        jdk 'JDK17'
    }
    
    environment {
        TOMCAT_HOME = '/opt/apache-tomcat-9.0.96'
        TOMCAT_WEBAPPS = "${TOMCAT_HOME}/webapps"
        WAR_FILE = 'lumiatech-v1.war'
    }
    
    stages {
        stage('Checkout') {
            steps {                
                sh 'git checkout main'
            }
        }
        
        stage('Build artifact') {
            steps {
                
                sh 'mvn clean package -DskipTests'
            }
            post {
                success {
                    echo '✓ Build successful!'
                    sh 'ls -lh target/*.war'
                }
            }
        }
        
        stage('Test') {
            steps {                
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Code Analysis') {
            steps {                
                sh 'mvn checkstyle:checkstyle'
            }
            post {
                success {
                    recordIssues(tools: [checkStyle(pattern: '**/target/checkstyle-result.xml')])
                }
            }
        }
        
        stage('Deploy to Tomcat') {
            steps {
                echo '========================================='
                echo 'Deploying application to Tomcat...'
                echo '========================================='
                
                script {
                    // Stop Tomcat
                    echo 'Stopping Tomcat...'
                    sh 'sudo systemctl stop tomcat9'
                    sh 'sleep 3'
                    
                    // Remove old deployment
                    echo 'Cleaning old deployment...'
                    sh """
                        sudo rm -rf ${TOMCAT_WEBAPPS}/ROOT
                        sudo rm -f ${TOMCAT_WEBAPPS}/ROOT.war
                    """
                    
                    // Verify cleanup
                    echo 'Verifying cleanup...'
                    sh "sudo ls -la ${TOMCAT_WEBAPPS}/ || true"
                    
                    // Copy new WAR file
                    echo 'Copying new WAR file...'
                    sh "sudo cp target/${WAR_FILE} ${TOMCAT_WEBAPPS}/ROOT.war"
                    
                    // Verify copy
                    echo 'Verifying deployment file...'
                    sh "sudo ls -lh ${TOMCAT_WEBAPPS}/ROOT.war"
                    
                    // Set ownership and permissions
                    echo 'Setting permissions...'
                    sh """
                        sudo chown tomcat:tomcat ${TOMCAT_WEBAPPS}/ROOT.war
                        sudo chmod 644 ${TOMCAT_WEBAPPS}/ROOT.war
                    """
                    
                    // Start Tomcat
                    echo 'Starting Tomcat...'
                    sh 'sudo systemctl start tomcat9'
                    
                    // Wait for Tomcat to start
                    echo 'Waiting for Tomcat to initialize...'
                    sh 'sleep 10'
                }
            }
            post {
                success {
                    echo '✓ Deployment successful!'
                }
                failure {
                    echo '✗ Deployment failed!'
                    sh 'sudo systemctl status tomcat9 || true'
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '========================================='
                echo 'Running health check...'
                echo '========================================='
                
                script {
                    // Wait a bit more for app initialization
                    sh 'sleep 5'
                    
                    // Check if Tomcat is running
                    sh 'sudo systemctl is-active tomcat9'
                    
                    // Check if application responds
                    def response = sh(
                        script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080',
                        returnStdout: true
                    ).trim()
                    
                    echo "HTTP Response Code: ${response}"
                    
                    if (response == '200' || response == '302') {
                        echo '✓ Application is responding correctly!'
                    } else {
                        echo "⚠ Warning: Unexpected HTTP response code: ${response}"
                    }
                    
                    // Check logs for Spring initialization
                    sh """
                        echo 'Checking Spring initialization in logs...'
                        sudo grep -i 'FrameworkServlet\\|WebApplicationContext: initialization completed\\|Server startup' \
                        ${TOMCAT_HOME}/logs/catalina.out | tail -5 || echo 'Spring logs not found yet'
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo '========================================='
            echo 'Pipeline Execution Complete'
            echo '========================================='
            cleanWs()
        }
        success {
            echo '✓ Pipeline completed successfully!'
            echo "Application URL: http://localhost:8080"
        }
        failure {
            echo '✗ Pipeline failed!'
            echo 'Check Tomcat logs for details:'
            echo "sudo tail -100 ${TOMCAT_HOME}/logs/catalina.out"
        }
    }
}