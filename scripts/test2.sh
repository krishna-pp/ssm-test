#!/bin/bash


function patch_server(){
  echo "Patching server"
  #yum -y update
 
  #exit with status 194 so SSM agent can reboot the server gracefully
  exit 194

}

patch_server
