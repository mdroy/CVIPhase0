#!/bin/bash
##################################################################
# Script Name   : generateZIP.sh
# Description   : This script run bash scripts and return response
# Args          : $1 --> Data Source ID
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
if [ $# -ne 2 ]; then
  printf "\nInvalid parameter value\n"
  exit 1
else
  export MODULE_ID="${1}"
fi
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf
logFile="/u01/app/cm/files/logs/tmp/zip_${MODULE_ID}_$$.log"

echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select a.sub_module_id||'|'||b.business_entity 
from XXCM_MIGRATION_SUB_MODULES a,
     XXCM_FBDI_CTL_FILES b
where a.module_id = "${MODULE_ID}"
and a.table_name is not null
and a.ctl_file_id = b.ctl_file_id
order by a.seq asc;
exit;"|sqlplus -s > $logFile

mkdir -p /u01/app/cm/files/logs/tmp/zipdir_${MODULE_ID}_$$
cd /u01/app/cm/files/logs/tmp/zipdir_${MODULE_ID}_$$
if [ -f $logFile ]; then
  for i in `cat $logFile`
  do
    sub_module_id=`echo $i|awk -F"|" '{print $1}'`
    csv_file_name=`echo $i|awk -F"|" '{print $2}'`
    csv_file_name="${csv_file_name}.csv"
    echo "$db_user/$db_password@$db_service
           exec xxcm_util_pub.write_csv_file("${sub_module_id}",'"${csv_file_name}"');
           exit;"|sqlplus -s > /dev/null 
    if [ -f "/u01/app/cm/files/logs/tmp/${csv_file_name}" ]; then
      mv /u01/app/cm/files/logs/tmp/${csv_file_name} /u01/app/cm/files/logs/tmp/zipdir_${MODULE_ID}_$$
    fi
  done
pwd
  zip "${2}.zip" *.csv
  mv "${2}.zip" /u01/app/cm/files/logs/tmp/
  chmod 775 "/u01/app/cm/files/logs/tmp/${2}.zip"
fi
rm -rf /u01/app/cm/files/logs/tmp/zipdir_${MODULE_ID}_$$
rm -rf $logFile
exit 0
