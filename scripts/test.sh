#!/bin/bash

. ./utils/utils.sh

PROD_PATCHING_WEEK=4
TEST_PATCHING_WEEK=1
SERVICE=org.apache.cassandra.service.CassandraDaemon
CASSANDRA_NODETOOL_COMMAND='/usr/bin/nodetool'


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

while getopts "pth:s:" opt; do
  case ${opt} in
    p ) patch_type=PROD
      ;;
    t ) patch_type=TEST
      ;;
    h ) nagios_host=$OPTARG
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

if [ -z $nagios_host ]
then 
  nagios_host=$(hostname)
fi

if is_patch_week $patch_type
then
  [ ! -z $sleep_seconds ] && sleep $sleep_seconds
  check_service
  schedule_nagios_downtime $nagios_host
  patch_server
fi
