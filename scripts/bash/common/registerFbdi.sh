#!/bin/bash
##################################################################
# Script Name   : registerFbdi.sh
# Description   : This script run bash scripts and return response
# Args          : $1 --> Data Source ID
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf
logFile=/u01/app/cm/files/logs/tmp/registerFbdi_$$.log

echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select ora_release||','||metadata_id||','||FBDI_XLSM
              from XXCM_ERP_CLOUD_METADATA m
             where metadata_type = 'Business Object'
               and FBDI_XLSM is not null
               and not exists (select null 
                                 from XXCM_FBDI_CTL_FILES c
                                where m.metadata_id = c.metadata_id);
exit;"|sqlplus -s > $logFile

for string in `cat $logFile`
do
    RELEASE=`echo $string|awk -F, '{print $1}'| tr '[:upper:]' '[:lower:]'`
    METADATA_ID=`echo $string|awk -F, '{print $2}'`
    FBDI_XLSM=`echo $string|awk -F, '{print $3}'`
    echo "https://www.oracle.com/webfolder/technetwork/docs/fbdi-${RELEASE}/fbdi/xlsm/$FBDI_XLSM"
    wget "https://www.oracle.com/webfolder/technetwork/docs/fbdi-${RELEASE}/fbdi/xlsm/$FBDI_XLSM" -P /u01/app/cm/files/logs/tmp/
    if [ -f "/u01/app/cm/files/logs/tmp/$FBDI_XLSM" ]; then
        python /u01/app/cm/scripts/python/common/registerFbdi.py "/u01/app/cm/files/logs/tmp/$FBDI_XLSM" "$METADATA_ID"
    fi
done
rm -rf $logFile
rm -rf /u01/app/cm/files/logs/tmp/*.xlsm
exit 0
