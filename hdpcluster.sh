#!/bin/bash

## 
## VARIABLES
## 

command=$1
args=$2
rundir=`pwd`
HDPCLUSTER_HOME=${HDPCLUSTER_HOME:-"~/hdpcluster"}
HDPCLUSTER_PROFILE=${HDPCLUSTER_PROFILE:-"KNOX101"}

##
## FUNCTIONS
##

function PrintHelp {
  echo "Usage:"
  echo "hdpcluster profile [<name>] - List available profiles, and set named profile active if one is specified"
  echo "           dns              - Add hosts in current profile to /etc/hosts"
  echo "           deploy           - Deploy the active profile"
  echo "           halt             - Shutdown hosts in the active profile"
  echo "           suspend          - Suspend hosts in the active profile"
  echo "           resume           - Resume hosts in the active profile"
  echo "           destroy          - Destroy the active cluster"
  echo "           status [<host>]  - List all hosts, or show status of specified host"
  echo "           ssh <host>       - ssh to the specified host"
  echo "           gui              - Graphical cluster design tool"
  echo "           help             - Print this help message"
}

function SetProfile {
  [ ! $args ] && echo "No profile specified, exiting" && exit 1

  profile_home="${HDPCLUSTER_HOME}/Profiles/${args}"

  # Verify profile contains required files
  [ ! -f "${profile_home}/structor.json" ] && echo "Profile missing structor.json, exiting" && exit 1
  [ ! -f "${profile_home}/blueprint.json" ] && echo "Profile missing blueprint.json, exiting" && exit 1
  [ ! -f "${profile_home}/hostgroups.json" ] && echo "Profile missing hostgroups.json, exiting" && exit 1
  [ ! -f "${profile_home}/hdp.repo" ] && echo "Profile missing hdp.repo, exiting" && exit 1
  [ ! -f "${profile_home}/ambari.repo" ] && echo "Profile missing ambari.repo, exiting" && exit 1
  export HDPCLUSTER_PROFILE=$args

  # Copy files into place
  rm -f ${HDPCLUSTER_HOME}/structor/current.profile \
    && echo "Removed old structor/current.profile"
  ln -s ${profile_home}/structor.json ${HDPCLUSTER_HOME}/structor/current.profile \
    && echo "Set structor/current.profile -> ${HDPCLUSTER_PROFILE}/structor.json"
  cp -a ${profile_home}/hdp.repo ${HDPCLUSTER_HOME}/structor/files/repos/hdp.repo \
    && echo "Set structor hdp.repo"
  cp -a ${profile_home}/ambari.repo ${HDPCLUSTER_HOME}/structor/files/repos/ambari.repo \
    && echo "Set structor ambari.repo"

  # Update DNS info
  UpdateDns
  
  # Apply Blueprint - TODO: make non-fqdn specific
  ApplyBlueprint mgmt.example.com "${profile_home}/blueprint.json" "${profile_home}/hostgroups.json"

  # SetProfile complete
  echo "Active profile: ${HDPCLUSTER_PROFILE}"
}

function ListProfiles {
  ls -1 ${HDPCLUSTER_HOME}/Profiles
}

function UpdateDns {
  uhpath="${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/update-hosts.sh"
  [ ! -e "${uhpath}" ] && echo "Profile missing update-hosts.sh, make edits manually" && exit 1
  [ ! -x "${uhpath}" ] && echo "Profile unable to execute update-hosts.sh, make edits manually" && exit 1
  $uhpath
}

function Deploy {
  cd ${HDPCLUSTER_HOME}/structor
  vagrant up
  cd $rundir
}

function Halt {
  cd ${HDPCLUSTER_HOME}/structor
  echo "TODO: vagrant halt \$ALL"
}

function Suspend {
  cd ${HDPCLUSTER_HOME}/structor
  echo "TODO: vagrant suspend \$ALL"
}

function Resume {
  cd ${HDPCLUSTER_HOME}/structor
  echo "TODO: vagrant resume \$ALL"
}

function Destroy {
  cd ${HDPCLUSTER_HOME}/structor
  echo "TODO: vagrant destroy \$ALL"
}

function ListHosts {
  cd ${HDPCLUSTER_HOME}/structor
  vagrant status
}

function SSH {
  cd ${HDPCLUSTER_HOME}/structor
  vagrant ssh $args
}

function LaunchGui {
  ${HDPCLUSTER_HOME}/http-server/bin/http-server ambari-node-view -o
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

## 
## Command parsing
## 

# Show help with run with no args
[ $# -eq 0 ] && PrintHelp && exit 0

# Process command
case $command in
  "profile")
    [ $args ] && SetProfile $args || ListProfiles
    ;;
  "dns")
    UpdateDns
    ;;
  "deploy")
    Deploy
    ;;
  "halt")
    Halt
    ;;
  "suspend")
    Suspend
    ;;
  "resume")
    Resume
    ;;
  "destroy")
    Destroy
    ;;
  "status")
    [ $args ] && Status $args || ListHosts
    ;;
  "ssh")
    [ $args ] && SSH $args || echo "Usage: hdpcluster ssh <host>"
    ;;
  "gui")
    LaunchGui
    ;;
  "help")
    PrintHelp
    ;;
  *)
    echo "hdpcluster: unknown command"
    ;;
esac

echo ''
## EOF
