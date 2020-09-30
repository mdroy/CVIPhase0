#!/bin/bash
##################################################################
# Script Name   : testSFTP.sh
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

string=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select 
HOSTNAME||','||
PORT||','||
HOSTKEY||','||
USERNAME||','||
PASSWORD||','||
'/u01/app/cm/files/snp/ds/'||ds_id||'_PVTKEY_'||PVTKEY_FILE_NAME||','||
PASSPHRASE||','||
'/u01/app/cm/files/snp/ds/'||ds_id||'_PGPPUBKEY_'||PGPPUBKEY_FILE_NAME||','||
'/u01/app/cm/files/snp/ds/'||ds_id||'_PGPPVTKEY_'||PGPPVTKEY_FILE_NAME||','||
PGP_PASSPHRASE||','||
AUTH_SCHEME
from XXCM_FTP_ATTRIBUTES
where ds_id = ${DS_ID}; 
exit;"|sqlplus -s`

HOSTNAME=`echo $string|awk -F, '{print $1}'`
PORT=`echo $string|awk -F, '{print $2}'`
HOSTKEY=`echo $string|awk -F, '{print $3}'`
USERNAME=`echo $string|awk -F, '{print $4}'`
PASSWORD=`echo $string|awk -F, '{print $5}'`
PVTKEY_FILE=`echo $string|awk -F, '{print $6}'`
PASSPHRASE=`echo $string|awk -F, '{print $7}'`
PGPPUBKEY_FILE=`echo $string|awk -F, '{print $8}'`
PGPPVTKEY_FILE=`echo $string|awk -F, '{print $9}'`
PGP_PASSPHRASE=`echo $string|awk -F, '{print $10}'`
AUTH=`echo $string|awk -F, '{print $11}'`
echo $HOSTNAME >> /tmp/sftptest_$$.txt
if [ $AUTH = "BA" ]; then
  ./testSFTPPasswd.sh $HOSTNAME $PORT $USERNAME $PASSWORD > /tmp/sftptest_$$.txt 2>&1
fi

if [ $? -eq 0 ] 
then
   echo "OK"
else
   echo "ERROR"
fi
