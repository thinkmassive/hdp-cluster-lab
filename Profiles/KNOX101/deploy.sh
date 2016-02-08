#!/bin/bash

ProfileDir=`pwd`
DEBUG=false

function ProvisionHosts {
  cd ${ProfileDir}/../../structor
  rm -f current.profile
  ln -s ${ProfileDir}/structor.json current.profile
  [ ${DEBUG} ] && pwd && ls -l
  vagrant up
}

function ApplyBlueprint {
  cd $ProfileDir
  AmbariHost=$1
  BlueprintFile=$2
  HostgroupsFile=$3
  [ ! "${AmbariHost}" ] && echo "No Ambari host supplied, exiting" && exit 1
  [ ! -e "${BlueprintFile}" ] && echo "Blueprint file not found, exiting" && exit 1
  [ ! -e "${HostgroupsFile}" ] && echo "Hostgroups file not found, exiting" && exit 1
  echo "Applying blueprint..."
  curl --user admin:admin -H 'X-Requested-By:mycompany' -X POST http://${AmbariHost}:8080/api/v1/blueprints/knox101 -d @${BlueprintFile}
  curl --user admin:admin -H 'X-Requested-By:mycompany' -X POST http://${AmbariHost}:8080/api/v1/clusters/hdpcluster -d @${HostgroupsFile}
  ProgressPercent=`curl -s --user admin:admin -H 'X-Requested-By:mycompany' -X GET http://${AmbariHost}:8080/api/v1/clusters/hdpcluster/requests/1 | grep progress_percent | awk '{print $3}' | cut -d . -f 1`
  echo " Progress: $ProgressPercent"

  while [[ `echo $ProgressPercent | grep -v 100` ]]; do
    ProgressPercent=`curl -s --user admin:admin -H 'X-Requested-By:mycompany' -X GET http://${AmbariHost}:8080/api/v1/clusters/hdpcluster/requests/1 | grep progress_percent | awk '{print $3}' | cut -d . -f 1`
    tput cuu1
    echo " Progress: $ProgressPercent %"
    sleep 2
  done
  echo ""
  echo "Cluster build is complete."
  echo "You may access the Ambari web interface at http://${AmbariHost}:8080"
  echo "User/pass: admin / admin"
}

ProvisionHosts 
ApplyBlueprint mgmt.example.com "${ProfileDir}/blueprint.json" "${ProfileDir}/hostgroups.json"
