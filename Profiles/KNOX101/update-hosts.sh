#!/bin/bash

echo ''

NONROOT=`id -u`
[ $NONROOT != "0" ] && echo -e "!! Running as non-superuser. Suggested changes will be shown, but no files will be modified. !!\n"

HOSTS_FILE=/etc/hosts
MYDOMAIN=example.com
EXIT_CODE=0
DEBUG=false

function AddHost {
  MYHOST=$1
  MYIP=$2
  FQDN="${MYHOST}.${MYDOMAIN}"
  EscFQDN=`echo $FQDN | sed 's/\./\\\./g'`
  EscIP=`echo $MYIP | sed 's/\./\\\./g'`
  HostLine=`grep "\<${EscFQDN}\>\|\<${MYHOST}\>" ${HOSTS_FILE}`
  IpLine=`grep "\<${EscIP}\>" ${HOSTS_FILE}`

  $DEBUG && echo "MYHOST: ${MYHOST}"
  $DEBUG && echo "MYIP: ${MYIP}"
  $DEBUG && echo "FQDN: ${FQDN}"
  $DEBUG && echo "EscFQDN: ${EscFQDN}"
  $DEBUG && echo "EscIP: ${EscIP}"
  $DEBUG && echo "HostLine: ${HostLine}"
  $DEBUG && echo "IpLine: ${IpLine}"

  #if [ `echo ${HostLine} | wc -l` != "" ]; then
  if [[ ${HostLine} ]]; then
    $DEBUG && echo "At least one matching: ${HostLine}"
    if [ "${HostLine}" == "${IpLine}" ]; then
      echo -e "INFO:\t${HOSTS_FILE} already contains '${HostLine}', skipping"
    else
      LineNum=`grep -n "\<${EscFQDN}\>\|\<${MYHOST}\>" ${HOSTS_FILE} | cut -f 1 -d : -`
      echo -e "ERROR:\t${HOSTS_FILE} contains conflicting entry for ${FQDN} on line ${LineNum}"
      EXIT_CODE=1
    fi
  else
    if [ `echo ${IpLine} | wc -l` ]; then
      LineNum=`grep -n "\<${EscIP}\>\|\<${MYHOST}\>" ${HOSTS_FILE} | cut -f 1 -d : -`
      echo -e "WARN:\t${HOSTS_FILE} contains another entry for ${MYIP} on line ${LineNum}"
    fi
    [ $NONROOT != "0" ] && echo -e "TODO:\tsudo sh -c 'echo \"${MYIP}  ${FQDN} ${MYHOST}\" >> ${HOSTS_FILE}'"
    [ $NONROOT == "0" ] && echo "${MYIP}  ${FQDN} ${MYHOST}" >> ${HOSTS_FILE} && echo -e "INFO:\tAdded ${MYIP}  ${FQDN} ${MYHOST}"
  fi
  $DEBUG && echo ''
}

AddHost mgmt 240.0.0.10
AddHost master01 240.0.0.11
AddHost master02 240.0.0.12
AddHost worker01 240.0.0.13

echo ''
exit ${EXIT_CODE}
