#!/bin/bash

CASSANDRA_NODETOOL_COMMAND='/usr/bin/nodetool'
SERVICE=org.apache.cassandra.service.CassandraDaemon
SLEEP_TIMEOUT=120

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
 
  #exit with status 194 so SSM agent can reboot the server gracefully
  exit 194

}

sleep $SLEEP_TIMEOUT
check_service
patch_server
