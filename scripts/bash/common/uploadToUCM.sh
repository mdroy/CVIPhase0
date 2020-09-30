#!/bin/bash
##################################################################
# Script Name   : testOracle.sh
# Description   : This script run bash scripts and return response
# Args          : $1 --> Data Source ID
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
if [ $# -ne 3 ]; then
  printf "\nInvalid parameter value\n"
  exit 1
else
  export INST_ID="${1}"
fi
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf
logFile="/u01/app/cm/files/logs/tmp/ucm_$$.log"

connString=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set linesize 2000
set echo off
set tab off
select INSTANCE_URL||'/cs/idcplg|'||
USER_NAME||'|'||
PASSWORD
from XXCM_CLOUD_ERP_INSTANCES
where instance_id = "${INST_ID}";
exit;"|sqlplus -s`
echo $connString >> $logFile
URL=`echo $connString|awk -F"|" '{print $1}'`
USERNAME=`echo $connString|awk -F"|" '{print $2}'`
PASSWORD=`echo $connString|awk -F"|" '{print $3}'`

export FILE="$2"
export UCM_ACC="$3"
echo $FILE >>  $logFile
echo $UCM_ACC >> $logFile

DOC_TITLE=`basename $FILE`
cd /u01/app/cm/ridc

RESPONSE=`${JAVA_HOME}/bin/java -jar ./oracle.ucm.fa_client_11.1.1.jar UploadTool --url="$URL" --username="$USERNAME" --password="$PASSWORD" --policy=oracle/wss_username_token_over_ssl_client_policy --primaryFile="$FILE" --dDocTitle="$DOC_TITLE" --dSecurityGroup=FAFusionImportExport --dDocAccount="$UCM_ACC"`
echo $RESPONSE >> $logFile
DOC_ID=`echo $RESPONSE|cut -f1 -d'|'|cut -f2 -d'['|cut -f2 -d'='|xargs`
echo $DOC_ID
exit 0
