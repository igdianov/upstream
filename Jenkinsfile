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
            sh "mvn versions:set -DnewVersion=$PREVIEW_VERSION"
            sh "mvn install"
            sh 'export VERSION=$PREVIEW_VERSION' //&& skaffold build -f skaffold.yaml'


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
            sh "git checkout master" 
            sh "git config --global credential.helper store"

            sh "jx step git credentials"
            // so we can retrieve the version in later steps
            sh "echo \$(jx-release-version) > VERSION"
            sh "mvn versions:set -DnewVersion=\$(cat VERSION)"
            
            // Let's test first
            sh "mvn clean verify"            

            // Let's make tag in Git            
            sh "git add --all"
            sh "git commit -m 'Release '\$(cat VERSION) --allow-empty"
            sh "git tag -fa v\$(cat VERSION) -m 'Release version '\$(cat VERSION)"
            sh "git push origin v\$(cat VERSION)"
            
          }
          // dir ('./charts/upstream') {
          //   container('maven') {
          //     sh "make tag"
          //   }
          // }
          container('maven') {
            sh 'mvn clean deploy'

            // sh 'export VERSION=`cat VERSION` && skaffold build -f skaffold.yaml'

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
            // Issue: jx step changelog cannot auto detect all commits changelog between prev and last tags on the release branch...
            sh """
                export VERSION=`cat VERSION`
                export REV=`git rev-list --tags --max-count=1 --grep '^Release'`        
                export PREVIOUS_REV=`git rev-list --tags --max-count=1 --skip=1 --grep '^Release'`

                echo Creating Github Changelog Release: $VERSION of `git show-ref --hash -- v$VERSION`
                echo Found commits between `git describe $PREVIOUS_REV` and `git describe $REV`:
                git rev-list $PREVIOUS_REV..$REV --first-parent --pretty

                jx step changelog --version v$VERSION --generate-yaml=false --rev=$REV --previous-rev=$PREVIOUS_REV
            """

            sh "echo doing updatebot push"
            sh "updatebot push --ref \$(cat VERSION)"

            //sh "echo doing updatebot push-version"
            //sh "updatebot push-version --kind maven org.example:upstream \$(cat VERSION)"

            // Let's wait for downstream CI pipeline status to automatically merge and close the PR
            sh "echo doing updatebot update-loop"
            sh "updatebot update-loop --poll-time-ms 60000"
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