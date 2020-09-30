#!/bin/bash
##################################################################
# Script Name   : testOracle.sh
# Description   : This script run bash scripts and return response
# Args          : $1 --> Data Source ID
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
if [ $# -ne 1 ]; then
  printf "\nInvalid parameter value\n"
  exit 1
else
  export DS_ID="${1}"
fi
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf

connString=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select 'echo \"exit\" | sqlplus -s \"'||username||'/'||password||'@'||HOSTNAME||':'||port || '/'||service_name||'\"' from XXCM_DB_ATTRIBUTES where ds_id = ${DS_ID};
exit;"|sqlplus -s`

OUTPUT=$(eval $connString 2>&1)

#echo "exit" | sqlplus -L $connString | grep Connected > /dev/null
if [ -z "$OUTPUT" ] 
then
   echo "OK"
else
   echo $OUTPUT
fi
