// Copyright (c) 2015 by Niklaus Giger niklaus.giger@member.fsf.org
// see http://jenkins-ci.org/content/pipeline-code-multibranch-workflows-jenkins
node {

  // Fill some variables
  def valid_submitters = 'anonymous' // ngiger jkappis mdescher'
  def mvnHome = tool 'M3'
  env.mvnHome = "${mvnHome}"
  deleteDir() // Start from fresh directory
  if (
        ("$BRANCH_2_BUILD" =~ '.*release.*' && "$VARIANT" =~ '.*snapshot.*') ||
        ("$BRANCH_2_BUILD" =~ '.*master.*'  && "$VARIANT" =~ '.*release.*')
    )  {
    sh "echo 'Invalid combination of VARIANT snapshot with branch $BRANCH_2_BUILD containing release' && exit 1"
  }

  checkout scm // populate the workspace with our scripts
  run_limit_acces('limit')

  // Avoid java.io.NotSerializableException: groovy.lang.IntRange$IntRangeIterator
  if ( "$RUN_MIRROR_4_ELEXIS"  == "true" ) {
    build_one_project("mirror.4.elexis", 'git://ng-tr/git/mirror.4.elexis.git')
  }
  if ( "$RUN_ELEXIS_3rd_PARTIES" == "true" ) {
    build_one_project("elexis.3rdparty.libraries", 'git://ng-tr/git/elexis.3rdparty.libraries.git');
  }
//  build_one_project("elexis-3-core", 'git://ng-tr/git/elexis-3-core.git');
  build_one_project("elexis-3-base", 'git://ng-tr/git/elexis-3-base.git');
//  build_one_project("medelexis-3-application". 'git://ng-tr/git/medelexis-3-application.git');

  def tests_okay = build_jubula()

  input message: "${tests_okay}\nSoll branch $BRANCH_2_BUILD jetzt freigeben werden?" // , submitter: valid_submitters
  run_limit_acces('unblock')
}

def run_limit_acces(access) {
  env.ACTION = access
  try {
    env.LIMIT_IPS = "$LIMIT_IPS"
  } catch(error) {
    env.LIMIT_IPS = "no IPS to limit"
  }
  env.VARIANT = "$VARIANT"
  sh "pwd; ls -l limit_access"
  sh "./limit_access"
}

def build_one_project(project_name, project_url)  {
  if (true) {
    echo "Calling groovy $project_name with BRANCH_NAME/VARIANT $BRANCH_2_BUILD/$VARIANT using withEnv"
    withEnv(["BRANCH_NAME=$BRANCH_2_BUILD",
             "VARIANT=$VARIANT"]) {
      dir(project_name) {
        deleteDir()
        sh 'pwd; ls -la; echo in build_one_project line 56'
        git  branch: "$BRANCH_2_BUILD",  url: project_url
        load 'build.groovy'
        // deleteDir() // deletes recursivlyCurrent direcotry
      }
    }
  }
  if (false) { // did not honour VARIANT
    echo "Calling build $project_name with BRANCH_NAME/VARIANT $BRANCH_2_BUILD/$VARIANT using withEnv"
    withEnv(["BRANCH_NAME=$BRANCH_2_BUILD",
             "VARIANT=$VARIANT"]) {
      build "$project_name"
    }
  }
  // when loading a jenkinsfile it allocate a new workspace@2 but does not do a checkout
  if (false) { // Did not honour BRANCH_2_BUILD = beta
    dir(project_name) {
      git url: 'git://ng-tr/git/elexis-3-base.git'
      env.BRANCH = "$BRANCH_2_BUILD"
      load 'build.groovy'
      // deleteDir() // deletes recursivlyCurrent direcotry
    }
  }
  if (false) { // did not work
    echo "Should build $project_name"
    sh "mkdir -p ${project_name}; ls -l ${project_name}"
    // when loading a jenkinsfile it allocate a new workspace@2 but does not do a checkout
    dir(project_name) {
      sh 'pwd; ls -la'
      git url: 'git://ng-tr/git/elexis-3-base.git'
      sh 'pwd; ls -l'
      load 'Jenkinsfile'
      sh 'pwd; ls -l'
      deleteDir() // deletes recursivlyCurrent direcotry
    }
  }
  if (false) {
    echo "Should build $project_name in a new node"
    node() {
      sh 'pwd; ls -la'
      git  url: 'git://ng-tr/git/elexis-3-base.git'
      sh 'pwd; ls -l'
      load 'Jenkinsfile'
      sh 'pwd; ls -l'
    }
  }
  echo "Done with $project_name"
}

def build_jubula() {
  def tests_okay = "Jubula GUI-Tests liefen noch nicht durch"
  return tests_okay;
  // Checkout Jubula GUI-Tests and run maven tests in a sub-directory
  checkout([$class: 'GitSCM', branches: [[name: '*/master']],
           doGenerateSubmoduleConfigurations: false,
           extensions: [[$class: 'RelativeTargetDirectory',
           relativeTargetDir: 'jubula']],
           submoduleCfg: [],
           userRemoteConfigs: [[url: "git://ng-tr/git/elexis-jubula.git"]]])
  try {
      sh "pwd; ls -la ; ls -la jubula; echo ${env.mvnHome}/bin/mvn; ls -l ${env.mvnHome}/bin/mvn"
      sh "cd jubula; ${env.mvnHome}/bin/mvn --batch-mode clean install"
      tests_okay = "Jubula GUI-Tests in Ordnung!"
      writeFile(file: "jubula/results/PASSED", text: "${tests_okay}")
  } catch (error) {
      tests_okay = "Jubula GUI-Tests schlugen fehl!"
      writeFile(file: "jubula/results/FAILURE", text: "${tests_okay}")
  }

  step([$class:  'ArtifactArchiver',
      artifacts: "jubula/results/**",
      fingerprint: true])
  return tests_okay;
}