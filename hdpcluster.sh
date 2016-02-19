#!/bin/bash

## 
## VARIABLES
## 

command=$1
args=$2
rundir=`pwd`
source ${HDPCLUSTER_HOME}/.config 2>/dev/null
HDPCLUSTER_HOME=${HDPCLUSTER_HOME:-"~/hdpcluster"}
HDPCLUSTER_PROFILE=${HDPCLUSTER_PROFILE:-"4node-nonsecure"}

##
## FUNCTIONS
##

function PrintHelp {
  echo "Usage (unavailable features marked by * ):"
  echo "hdpcluster profile [<name>] - List available profiles, and set named profile active if one is specified"
  echo "           dns              - Add hosts in current profile to /etc/hosts"
  echo "           deploy           - Deploy the active profile"
  echo "           halt             - Shutdown hosts in the active profile"
  echo "           suspend          - Suspend hosts in the active profile"
  echo "         * resume           - Resume hosts in the active profile"
  echo "           destroy          - Destroy the active cluster"
  echo "           status [<host>]  - List all hosts, or show status of specified host"
  echo "           ssh <host>       - ssh to the specified host"
  echo "           gui              - Graphical cluster design tool"
  echo "           help             - Print this help message"
  ListActiveProfile
}

function SetProfile {
  [ ! $args ] && echo "No profile specified, exiting" && exit 1

  profile_home="${HDPCLUSTER_HOME}/Profiles/${args}"
  profile_error=0

  # Verify profile contains required files
  [ ! -d "${profile_home}" ] && echo "Profile directory ${profile_home} does not exist" && (( profile_error++ ))
  [ ! -f "${profile_home}/structor.json" ] && echo "Profile missing structor.json" && (( profile_error++ ))
  [ ! -f "${profile_home}/blueprint.json" ] && echo "Profile missing blueprint.json" && (( profile_error++ ))
  [ ! -f "${profile_home}/hostgroups.json" ] && echo "Profile missing hostgroups.json" && (( profile_error++ ))
  [ ! -f "${profile_home}/hdp.repo" ] && echo "Profile missing hdp.repo" && (( profile_error++ ))
  [ ! -f "${profile_home}/ambari.repo" ] && echo "Profile missing ambari.repo" && (( profile_error++ ))
  [ $profile_error -gt 0 ] && echo "Error setting new profile, exiting." && ListActiveProfile && exit 1

  # Set new active profile
  export HDPCLUSTER_PROFILE=$args

  # Copy files into place
  rm -f ${HDPCLUSTER_HOME}/structor/current.profile # && echo "Removed old structor/current.profile"
  ln -s ${profile_home}/structor.json ${HDPCLUSTER_HOME}/structor/current.profile # && echo "Set structor/current.profile -> ${HDPCLUSTER_PROFILE}/structor.json"
  cp -a ${profile_home}/hdp.repo ${HDPCLUSTER_HOME}/structor/files/repos/hdp.repo # && echo "Set structor hdp.repo"
  cp -a ${profile_home}/ambari.repo ${HDPCLUSTER_HOME}/structor/files/repos/ambari.repo # && echo "Set structor ambari.repo"

  # Update .config file
  conf_file=${HDPCLUSTER_HOME}/.config
  if [ -f "${conf_file}" ]; then
    if [ `grep 'HDPCLUSTER_PROFILE' $conf_file | wc -l` -gt 0 ]; then
      text_replace="s/HDPCLUSTER_PROFILE=.*/HDPCLUSTER_PROFILE=${HDPCLUSTER_PROFILE}/g"
      sed -e "${text_replace}" -i .bak "${conf_file}"
    else
      echo "HDPCLUSTER_PROFILE=${HDPCLUSTER_PROFILE}" >> ${conf_file}
    fi
  fi

  # SetProfile complete
  ListActiveProfile
  echo "Update /etc/hosts by executing: hdpcluster dns"

}

function ListActiveProfile {
  echo ''
  echo "Active profile: ${HDPCLUSTER_PROFILE}"
  echo ''
}

function ListProfiles {
  echo 'Available profiles:'
  ls -1 ${HDPCLUSTER_HOME}/Profiles
  ListActiveProfile
}

function UpdateDns {
  uhpath="${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/update-hosts.sh"
  [ ! -e "${uhpath}" ] && echo "Profile missing update-hosts.sh, make edits manually" && exit 1
  [ ! -x "${uhpath}" ] && echo "Profile unable to execute update-hosts.sh, make edits manually" && exit 1
  $uhpath
}

function Deploy {
  cd ${HDPCLUSTER_HOME}/structor
  vagrant up --provider virtualbox
  cd $rundir

  # Apply Blueprint - TODO: make non-fqdn specific
  ApplyBlueprint mgmt.example.com 

}

function Status {
  args=$1
  cd "${HDPCLUSTER_HOME}/structor"
  vagrant status $args
  cd "$rundir"
}

function Halt {
  cd "${HDPCLUSTER_HOME}/structor"
  vagrant status | grep virtualbox | grep running | awk '{print $1}' | xargs vagrant halt
  cd "$rundir"
}

function Suspend {
  cd "${HDPCLUSTER_HOME}/structor"
  vagrant status | grep virtualbox | grep running | awk '{print $1}' | xargs vagrant suspend
  cd "$rundir"
}

function Resume {
  cd "${HDPCLUSTER_HOME}/structor"
  vagrant status | grep virtualbox | grep saved | awk '{print $1}'| xargs vagrant resume
  vagrant status | grep virtualbox | grep running | awk '{print $1}'| xargs vagrant reload
  cd "$rundir"
}

function Destroy {
  read -r -p "CLUSTER WILL BE DESTROYED!  Type 'yes' to proceed, anything else to cancel: " input
  [ $input != "yes" ] && echo "Exiting." && exit 0
  
  cd "${HDPCLUSTER_HOME}/structor"
  vagrant status | grep virtualbox | awk '{print $1}' | xargs vagrant destroy -f
  cd "$rundir"
}

function SSH {
  echo ''
  echo ''
  echo 'To become root in the VM: sudo su -'
  echo ''
  echo ''
  cd ${HDPCLUSTER_HOME}/structor
  vagrant ssh $args
  cd "$rundir"
}

function LaunchGui {
  ${HDPCLUSTER_HOME}/http-server/bin/http-server ${HDPCLUSTER_HOME}/ambari-node-view -o
}


function ApplyBlueprint {
  AmbariHost=$1
  profile_home="${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}"
  BlueprintFile=${profile_home}/blueprint.json
  HostgroupsFile=${profile_home}/hostgroups.json
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
  "blueprint")
    ApplyBlueprint mgmt.example.com 
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
    Status $args
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
