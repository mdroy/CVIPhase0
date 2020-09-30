#!/bin/bash
##################################################################
# Script Name   : getDecPasswd.sh
# Description   : This script decrypt a given encrypted  password
# Args          : $1 --> un encrypted password
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
if [ $# -ne 1 ]; then
  printf "\nInvalid parameter value\n"
  exit 1
else
  export passWord="${1}"
fi
source /u01/app/cm/config/app.conf
if [ ! -z "$1" ]; then
    passWord=`echo "$passWord" | openssl enc -aes-128-cbc -a -d -salt -pass pass:"$app_salt"`
    echo "$passWord"
else
    exit 1	
fi
exit 0


