# hdpcluster
A utility to provide rapid HDP cluster deployment for testing and training purposes. It stands on the shoulders of giants, including [structor](https://github.com/hortonworks/structor), [ambari-node-view](https://github.com/mr-jstraub/ambari-node-view), and [Apache Ambari](https://github.com/apache/ambari).

## Installation:
-  `git clone https://github.com/thinkmassive/hdpcluster.git`
-  `./hdpcluster/install.sh`

### Quick Start:
After installation, execute the following commands to deploy a secured 4-node cluster with NN HA, Hive, and Knox:
- `hdpcluster profile KNOX101`
- `hdpcluster deploy`
- `ssh root@mgmt.example.com` (password: hadoop)

## Notes

**This project is under heavy development and is subject to backwards-incompatible changes until this message is removed.**

The initial state of this project is essentially a shell script that wraps the underlying tools for ease of use. Improvements coming soon. Pull requests welcome.

## Operation:

|Command|Description|
|-------|-----------|
|`hdpcluster profile [<name>]`|List available profiles, and set named profile active if one is specified|
|`hdpcluster dns`|Add hosts in current profile to /etc/hosts|
|`hdpcluster deploy`|Deploy hosts in the active profile|
|`hdpcluster destroy`|Destroy the active cluster|
|`hdpcluster status [<host>]`|List all hosts, or show status of specified host|
|`hdpcluster ssh <host>`|ssh to the specified host|
|`hdpcluster gui`|Graphical cluster design tool|
|`hdpcluster help`|Prints this help message|

## Profiles:

A profile consists of a directory that defines the profile name and contains the following files:

|Filename|Description|
|--------|-----------|
|blueprint.json|Ambari blueprint|
|hostgroups.json|Ambari hostgroups|
|structor.json|Structor current.profile|
|ambari.repo|Yum repo for Ambari|
|hdp.repo|Yum repo for HDP|
|update-hosts.sh|Shell script to update /etc/hosts (this will go away soon)|
