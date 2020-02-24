#!/bin/bash


function schedule_nagios_downtime() {
  local host=$1
  local user=nagiosadmin
  local pass=banan
  local comment="Maintenance by SSM"
  local curl_timeout=2
  local minutes=20

  declare -A nagios_hosts=(["nonpci-nagios-ie-a"]="10.12.11.137" ["sun-nagios-ie-b"]="10.48.49.217" ["nagios1-sp-a"]="10.48.41.196" ["nagios1-ie-a"]="10.48.49.196" ["nagios1-ca-b"]="10.48.25.196" ["nagios1-ff-a"]="10.48.70.168" )
  
  for nagios_host in "${!nagios_hosts[@]}"; do

    echo "Scheduling downtime on $host against $nagios_host"

    nag_url=https://${nagios_hosts[$nagios_host]}/nagios/cgi-bin/cmd.cgi 
    start_date=`date "+%Y-%m-%d %H:%M:%S"`
    end_date=`date "+%Y-%m-%d %H:%M:%S" -d "$minutes min"`
    curl --silent --show-error \
        --data cmd_typ=86 \
        --data cmd_mod=2 \
        --data host=$host \
        --data-urlencode "com_data=$comment" \
        --data trigger=0 \
        --data-urlencode "start_time=$start_date" \
        --data-urlencode "end_time=$end_date" \
        --data fixed=1 \
        --data hours=2 \
        --data minutes=0 \
        --data btnSubmit=Commit \
        --insecure \
        --max-time $curl_timeout \
        $nag_url -u "$user:$pass"| grep -q "Your command request was successfully submitted to Nagios for processing."
  done 
  

}

function is_patch_week() {

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
