pipeline {
    agent none
    environment {
        DOCKERHUB_CREDENTIALS = credentials('DockerLogin')
        //SNYK_CREDENTIALS = credentials('SnykToken')
    }
    stages {
        stage('Secret Scanning Using Trufflehog') {
            agent {
                docker {
                    image 'trufflesecurity/trufflehog:latest'
                    args '-u root --entrypoint='
                }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh 'trufflehog filesystem . --exclude-paths trufflehog-excluded-paths.txt --fail --json > trufflehog-scan-result.json'
                }
                sh 'cat trufflehog-scan-result.json'
                archiveArtifacts artifacts: 'trufflehog-scan-result.json'
            }
        }
        stage('Build') {
            agent {
              docker {
                  image 'node:lts-buster-slim'
              }
            }
            steps {
                sh 'npm install'
            }
        }
        // stage('Test') {
        //     agent {
        //       docker {
        //           image 'node:lts-buster-slim'
        //       }
        //     }
        //     steps {
        //         sh 'npm run test'
        //     }
        // }
        stage('SCA Trivy Scan Dockerfile Misconfiguration') {
            agent {
              docker {
                  image 'aquasec/trivy:latest'
                  args '-u root --network host --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'trivy config Dockerfile --exit-code=1 > trivy-scan-dockerfile-report.txt'
                }
                sh 'cat trivy-scan-dockerfile-report.txt'
                archiveArtifacts artifacts: 'trivy-scan-dockerfile-report.txt'
            }
        }
        stage('SAST SonarQube') {
            agent {
              docker {
                  image 'sonarsource/sonar-scanner-cli:latest'
                  args '--network host -v ".:/usr/src" --entrypoint='
              }
            }
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                    sh 'sonar-scanner -Dsonar.projectKey=nodedashboard -Dsonar.qualitygate.wait=true -Dsonar.sources=. -Dsonar.host.url=http://192.168.240.1:9000 -Dsonar.token=sqp_4201d29a9875e0bd65bd0281204da54974198970' 
                }
            }
        }
        stage('Build Docker Image and Push to Docker Registry') {
            agent {
                docker {
                    image 'docker:dind'
                    args '--user root --network host -v /var/run/docker.sock:/var/run/docker.sock'
                }
            }
            steps {
                timeout(time: 15, unit: "MINUTES"){
                  input message: 'Waiting Approval Deployment ?', ok: 'Yes'
                }
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh 'docker build -t alifadi/nodedashboard:0.1 .'
                sh 'docker push alifadi/nodedashboard:0.1'
            }
        }
        stage('Deploy Docker Image') {
            agent {
                docker {
                    image 'kroniak/ssh-client'
                    args '--user root --network host'
                }
            }
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: "DeploymentSSHKey", keyFileVariable: 'keyfile')]) {
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no jenkins@192.168.240.254 "echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin"'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no jenkins@192.168.240.254 docker pull alifadi/nodedashboard:0.1'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no jenkins@192.168.240.254 docker rm --force nodedashboard'
                    sh 'ssh -i ${keyfile} -o StrictHostKeyChecking=no jenkins@192.168.240.254 docker run -it --detach -p 8080:8080 --name nodedashboard --network host alifadi/nodedashboard:0.1'
                }
            }
        }
       stage('DAST Nuclei') {
           agent {
               docker {
                   image 'projectdiscovery/nuclei'
                   args '--user root --network host --entrypoint='
               }
           }
           steps {
               catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                   sh 'nuclei -u http://192.168.240.254:8080 -j > nuclei-report.json'
                   sh 'cat nuclei-report.json'
               }
               archiveArtifacts artifacts: 'nuclei-report.json'
           }
       }
//        stage('DAST OWASP ZAP') {
//            agent {
//                docker {
//                    image 'owasp/zap2docker-stable:latest'
//                    args '-u root --network host -v /var/run/docker.sock:/var/run/docker.sock --entrypoint= -v .:/zap/wrk/:rw'
//                }
//            }
//            steps {
//                catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
//                    sh 'zap-full-scan.py -t http://192.168.1.84:4000 -r zapfull.html -x zapfull.xml'
//                }
//                sh 'cp /zap/wrk/zapfull.html ./zapfull.html'
//                sh 'cp /zap/wrk/zapfull.xml ./zapfull.xml'
//                archiveArtifacts artifacts: 'zapfull.html'
//                archiveArtifacts artifacts: 'zapfull.xml'
//            }
//        }
    }
//    post {
//        always {
//            node('built-in') {
//                sh 'curl -X POST http://localhost:8080/api/v2/import-scan/ -H "Authorization: Token 4352361ac0640d6cb3284e5354f194fc89344c14" -F "scan_type=Trufflehog Scan" -F "file=@./trufflehog-scan-result.json;type=application/json" -F "engagement=1"'
//                sh 'curl -X POST http://localhost:8080/api/v2/import-scan/ -H "Authorization: Token 4352361ac0640d6cb3284e5354f194fc89344c14" -F "scan_type=Nuclei Scan" -F "file=@./nuclei-report.json;type=application/json" -F "engagement=1"'
//                sh 'curl -X POST http://localhost:8080/api/v2/import-scan/ -H "Authorization: Token 4352361ac0640d6cb3284e5354f194fc89344c14" -F "scan_type=ZAP Scan" -F "file=@./zapfull.xml;type=text/xml" -F "engagement=1"'
//            }
//        }
//   }
}
