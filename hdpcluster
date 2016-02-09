#!/bin/bash

## 
## VARIABLES
## 

command=$1
args=$2
rundir=`pwd`
HDPCLUSTER_HOME= TODO
HDPCLUSTER_PROFILE=$HDPCLUSTER_PROFILE: TODO

##
## FUNCTIONS
##

function PrintHelp {
  echo "Usage:"
  echo "hdpcluster profile [<name>] - List available profiles, and set named profile active if one is specified"
  echo "           updatehosts      - Add hosts in current profile to /etc/hosts"
  echo "           deploy           - Deploy the active profile"
  echo "           halt             - Shutdown hosts in the active profile"
  echo "           suspend          - Suspend hosts in the active profile"
  echo "           resume           - Resume hosts in the active profile"
  echo "           destroy          - Destroy the active cluster"
  echo "           hosts            - List hosts"
  echo "           ssh <host>       - ssh to the specified host"
  echo "           status <host>    - Show status of specified host"
  echo "           gui              - Graphical cluster design tool"
  echo "           help             - Print this help message"
}

function SetProfile {
  [ $args ] && ${HDPCLUSTER_PROFILE}=$args || echo "No profile specified"
}

function ListProfiles {
  ls -1 ${HDPCLUSTER_HOME}/Profiles
}

function UpdateHosts {
  ${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/update-hosts.sh
}

function Deploy {
  # Copy profile files into place
  rm -f ${HDPCLUSTER_HOME}/structor/current.profile \
    && echo "Removed structor/current.profile"
  ln -s ${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/structor.json ${HDPCLUSTER_HOME}/structor/current.profile \
    && echo "Set structor/current.profile -> ${HDPCLUSTER_PROFILE}/structor.json"
  cp -a ${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/hdp.repo ${HDPCLUSTER_HOME}/structor/files/repos/hdp.repo \
    && echo "Set structor hdp.repo"
  cp -a ${HDPCLUSTER_HOME}/Profiles/${HDPCLUSTER_PROFILE}/ambari.repo ${HDPCLUSTER_HOME}/structor/files/repos/ambari.repo \
    && echo "Set structor ambari.repo"
  cd ${HDPCLUSTER_HOME}/structor

  # Start VMs
  vagrant up

  # Finish
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
  "deploy")
    Deploy
    ;;
  "start")
    Start
    ;;
  "stop")
    Stop
    ;;
  "destroy")
    Destroy
    ;;
  "hosts")
    ListHosts
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
    echo "unknown command"
    ;;
esac

