#!/bin/bash

# REMOVE OLD BACKUP FILES
rm -rf /usr/local/opt/jenkins/backup/* 2> /dev/null
# CHECK LATEST STABLE VERSION and assign it to 'last_lts_version'
last_lts_version=$(curl https://formulae.brew.sh/api/formula/jenkins-lts.json |  python3 -c "import sys, json; print(json.load(sys.stdin)['versions']['stable'])")
# CHECK CURRENT VERSION and assign it to 'current_lts_version'
current_lts_version=$(cat /usr/local/opt/jenkins/version)

printf "*****************************************\n*    LAST STABLE VERSION IS: $last_lts_version    *\n*****************************************\n*      CURRENT VERSION IS: $current_lts_version      *\n*****************************************\n "
# If new lts version has been released then update the current version using brew package manager or proceed the following steps:
if [ $last_lts_version == $current_lts_version ]; then
    :
    else

      if [[ $(brew services list |grep -i jenkins | awk '{print $2}') == 'started' ]] || [[ $(brew services list |grep -i jenkins | awk '{print $2}') == 'error' ]] ; then
          echo "---> Stopping Jenkins Service"
          brew services stop jenkins
          sleep 10
          else
            :
      fi

      echo "---> Backing up existing Jenkins .war file"
      # If backup directory does not exits, then create it
      if [[ -e /usr/local/opt/jenkins/backup/ ]]; then
         :
         else
           mkdir /usr/local/opt/jenkins/backup/
      fi
      # Take a backup of old .war file
      mv /usr/local/opt/jenkins/libexec/jenkins.war /usr/local/opt/jenkins/backup/jenkins-${current_lts_version}.war

      # Download .war file or use brew to update
      echo "---> Getting latest Jenkins .war file"
      # brew upgrade jenkins-lts OR
      curl -LO http://updates.jenkins-ci.org/download/war/${last_lts_version}/jenkins.war && mv jenkins.war /usr/local/opt/jenkins/libexec/
      sleep 10

      # Start Service
      echo "---> Starting Jenkins"
      brew services start jenkins
      sleep 10

      # Check Services' Status
      echo "---> Checking Service Up & Running"
      if [ $(brew services list |grep -i jenkins | awk '{print $2}') == 'started' ]; then
          echo "JENKINS IS RUNNING!"
          echo "---> Editting 'version' File"
          echo ${last_lts_version} > /usr/local/opt/jenkins/version
          echo "Jenkins Upgrade Operation Has Been Completed!"
          else
            echo "JENKINS COULD NOT WORK PROPERLY, PLEASE REPORT THIS TO DEVOPS TEAM!"
      fi
fi

