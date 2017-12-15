#!/usr/bin/env groovy

//This jenkins file is used in Jenkins multibranch pipeline otherwise env.BRANCH_NAME will return null.
//Input message is used to prompt confirmation for proceeding to deploy step or not.


node {

	def theme = 'testing'
	def server = 'testing.aws.staging'
	
	if (env.BRANCH_NAME == 'release') {
		theme = 'staging'
		server = 'staging.aws.staging'
	}	

	stage('Checkout') {
		checkout scm
	}
	
	stage('Install Dependencies') {
		sh "bin/install_deps.sh"
	}
	stage('Check Code') {
		sh "echo bin/checkcode.sh"
	}
	stage('Test') {
		sh "echo bin/test.sh"
	}
	stage('Build') {
		if (env.BRANCH_NAME == 'release' || env.BRANCH_NAME == 'master') {
			sh "bin/build.sh ${theme}"
		}
	}
	stage('Archive') {
		if (env.BRANCH_NAME == 'release' || env.BRANCH_NAME == 'master') {
			archiveArtifacts 'releases/*.tar.gz'
		}
	}
	stage('Deploy') {
		if (env.BRANCH_NAME == "release") {
			input message: "Proceed to deploy?"
			sh "bin/deploy.sh ${server} ${theme}"
		}

		if (env.BRANCH_NAME == "master") {
			sh "bin/deploy.sh ${server} ${theme}"
		}
	}
}