#!/bin/bash

PROD_PATCHING_WEEK=3
TEST_PATCHING_WEEK=1
SERVICE=org.apache.cassandra.service.CassandraDaemon
CASSANDRA_NODETOOL_COMMAND='/usr/bin/nodetool'

function is_patching_week() {

  local patch_type=$1
  local patching_week=$(eval echo \$${patch_type}_PATCHING_WEEK)
  local week_of_month=$((($(date +%-d)-1)/7+1))

  if [[ "$patching_week" == "$week_of_month" ]]
  then
    echo "Its $patch_type patching week"
    return 0
  else 
    echo "Its not $patch_type patching week"
    return 1
  fi
}

function check_cluster_up() {

  local cluster_status
  local abnormal_count

  cluster_status=$(eval "$CASSANDRA_NODETOOL_COMMAND status")
  abnormal_count=$(echo "$cluster_status" | grep -E "^.L|^.J|^.M|^DN" | wc -l)

  if [[ "$abnormal_count" != "0" ]]; then
    echo "Aborting! All cluster nodes are not up!"
    echo
    echo "$cluster_status"
    exit 1
  fi
}

function check_service() {
  if ps ax | grep -v grep | grep $SERVICE > /dev/null
  then
    echo "$SERVICE service is running"
    check_cluster_up
  else
    echo "$SERVICE is not running"
    exit 2
  fi
}

function patch_server(){
  echo "Patching server"
  yum -y update
  needs-restarting -r
  if [ $? -eq 1 ]
  then 
    # Exit with status code 194 so SSM can reboot the instance gracefully
    exit 194
  else 
    exit 0
  fi
}

while getopts "pts:" opt; do
  case ${opt} in
    p ) patch_type=PROD
      ;;
    t ) patch_type=TEST
      ;;
    s ) sleep_seconds=$OPTARG
      ;;
    \? ) echo "Usage: $0 [-p] [-t] -s <sleep>"
         exit 0
      ;;
  esac
done


if [ -z $patch_type ]
then
  patch_type=PROD
fi

if is_patching_week $patch_type
then
  [ ! -z $sleep_seconds ] && sleep $sleep_seconds
  check_service
  patch_server
fi
