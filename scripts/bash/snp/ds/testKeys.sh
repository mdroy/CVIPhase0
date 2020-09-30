#!/bin/bash
##################################################################
# Script Name   : testKeys.sh
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

keyFiles=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select DS_ID||'_PVTKEY_'||PVTKEY_FILE_NAME||':'|| 
       DS_ID||'_PGPPUBKEY_'||PGPPUBKEY_FILE_NAME||':'||
       DS_ID||'_PGPPVTKEY_'||PGPPVTKEY_FILE_NAME
from XXCM_FTP_ATTRIBUTES
where ds_id = ${DS_ID};
exit;"|sqlplus -s`

cd /u01/app/cm/files/snp/ds
export IFS=":"
for f in $keyFiles; 
do
   if [ -f "$f" ]
   then
       if [[ $f == *_PVTKEY_* ]]
       then
           openssl rsa -in "$f" -check -noout
       elif [[ $f == *_PGPPUBKEY_* ]]
       then
           fingerPrintPub=`gpg --with-fingerprint $f |grep "Key fingerprint"|cut -f2 -d'='|cut -c2-`
       elif [[ $f == *_PGPPVTKEY_* ]]
       then
           fingerPrintPvt=`gpg --with-fingerprint $f |grep "Key fingerprint"|cut -f2 -d'='|cut -c2-`
       fi
   fi
done
if ! [ "${fingerPrintPub//[[:blank:]]/}" = "${fingerPrintPvt//[[:blank:]]/}" ]; then
    echo "PGP key Finger print does not match"
    exit 1
fi
echo "Successfully tested"
exit 0
