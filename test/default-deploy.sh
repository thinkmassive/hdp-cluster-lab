#!/bin/bash

## Run from main project dir

#ProjDir=`pwd`
#TestDir=$ProjDir/test
ProjDir=`pwd`
TestDir=$ProjDir/test
TestTime=`date +%s`
Log="$TestDir/logs/${TestTime}.log"
Out="$TestDir/logs/${TestTime}.out"

function SmokeTestHdfs {
  # Determine if you can reach the NameNode server with your browser:
  curl http://master01.example.com:50070

  # Create the hdfs user directory in HDFS:
  ssh root@mgmt.example.com "sudo su - hdfs -c 'hdfs dfs -mkdir -p /user/hdfs'"

  # Try copying a file into HDFS and listing that file:
  ssh root@mgmt.example.com "sudo su - hdfs -c 'hdfs dfs -copyFromLocal /etc/passwd passwd && hdfs dfs -ls'"

  # Test WebHDFS
}

function SmokeTestYarn {
  # Browse to the ResourceManager:
  curl http://$resourcemanager.full.hostname:8088/

  # Create a $CLIENT_USER in all of the nodes and add it to the users group.
  ssh root@mgmt.example.com 'usermod -a -G users root'

  # As the HDFS user, create a /user/$CLIENT_USER.
  ssh root@mgmt.example.com "su - hdfs -c 'hdfs dfs -mkdir /user/root && hdfs dfs -chown root:root /user/root && hdfs dfs -chmod -R 755 /user/root'"

  # Run the smoke test as the $CLIENT_USER. Using Terasort, sort 10GB of data.
  ssh root@mgmt.example.com "/usr/hdp/current/hadoop-client/bin/hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-*.jar teragen 10000 tmp/teragenout"
  ssh root@mgmt.example.com "/usr/hdp/current/hadoop-client/bin/hadoop jar /usr/hdp/current/hadoop-mapreduce-client/hadoop-mapreduce-examples-*.jar terasort tmp/teragenout tmp/terasortout"
}


touch $Log
$ProjDir/hdpcluster.sh destroy -y
$ProjDir/hdpcluster.sh profile default

echo "Logging timers to $Out, console output to $Log"
echo "Executing $ProjDir/hdpcluster.sh:"
ls -l $ProjDir/hdpcluster.sh

for i in {1..3}; do
  echo $(time "$ProjDir/hdpcluster.sh deploy" 2>&1 >> $Log) 2>&1 >> $Out
#  `time sh -c "$ProjDir/hdpcluster.sh deploy" 2>&1 >> $Log` 2>&1 >> $Out
#  `time SmokeTestHdfs 2>&1 >> $Log` 2>&1 >> $Out
#  `time SmokeTestYarn 2>&1 >> $Log` 2>&1 >> $Out
  $ProjDir/hdpcluster.sh destroy -y
  $ProjDir/hdpcluster.sh profile default
done
