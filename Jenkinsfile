pipeline {
    agent {
      label "jenkins-maven"
    }
    environment {
      ORG               = 'igdianov'
      APP_NAME          = 'upstream'
      CHARTMUSEUM_CREDS = credentials('jenkins-x-chartmuseum')
    }
    stages {
      stage('CI Build and push snapshot') {
        when {
          branch 'PR-*'
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          container('maven') {
            sh "make preview"
            
           // sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:$PREVIEW_VERSION"
          }

          // dir ('./charts/preview') {
          //  container('maven') {
          //    sh "make preview"
          //    sh "jx preview --app $APP_NAME --dir ../.."
          //  }
          // }
        }
      }
      stage('Build Release') {
        when {
          branch 'master'
        }
        steps {
          container('maven') {
            // ensure we're not on a detached head
            sh "make checkout"

            // so we can retrieve the version in later steps
            sh "make version"
            
            // Let's test first
            sh "make verify"            

            // Let's make tag in Git            
            sh "make tag"
          }
          // dir ('./charts/upstream') {
          //   container('maven') {
          //     sh "make tag"
          //   }
          // }
          container('maven') {
            sh "make deploy"
            // sh "jx step post build --image $DOCKER_REGISTRY/$ORG/$APP_NAME:\$(cat VERSION)"
          }
        }
      }
      stage('Promote Version') {
        when {
          branch 'master'
        }
        steps {
          container('maven') {

            // Let's publish release notes in Github using commits between previous and last tags
            sh "make changelog"

            // Let's push changes and open PRs to downstream repositories
            sh "make push"

            //sh "make push-version"

            // Let's wait for downstream CI pipeline status to automatically merge and close the PR
            sh "make update-loop"
          }
        }
     }

/*
      stage('Promote to Environments') {
        when {
          branch 'master'
        }
        steps {
          
          dir ('./charts/upstream') {
              container('maven') {
                // sh 'jx step changelog --version v\$(cat ../../VERSION)'
    
                // release the helm chart
                sh 'jx step helm release'
    
                // promote through all 'Auto' promotion Environments
                sh 'jx promote -b --all-auto --timeout 1h --version \$(cat ../../VERSION)'
              }
            }
        }
      }
*/      

    }
    post {
        success {
            cleanWs()
        }
        failure {
            input """Pipeline failed. 
We will keep the build pod around to help you diagnose any failures. 
Select Proceed or Abort to terminate the build pod"""
        }
    }
}