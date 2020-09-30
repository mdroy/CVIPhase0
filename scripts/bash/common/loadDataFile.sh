#!/bin/bash
##################################################################
# Script Name   : loadDataFile.sh
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

if [ $# -ne 3 ]; then
    printf "\nInvalid parameter value\n"
    exit 1
else
    dataDefId="$1"
    fileName="$2"
    execId="$3"
fi
cd /u01/app/cm/files/snp/modules/srcdata
echo "$db_user/$db_password@$db_service
SET ECHO OFF;
SET HEAD OFF;
SET PAGESIZE 0;
SET LINESIZE 2000;
SET UNDERLINE OFF;
SET FEED OFF;
SET TAB OFF;
SET VER OFF;
SET TRIMSPOOL ON
SPOOL "${dataDefId}".ctl

SELECT 'OPTIONS (SKIP=1) 
LOAD DATA 
INFILE ''/u01/app/cm/files/snp/modules/srcdata/"${fileName}"''
REPLACE INTO TABLE '
       || TABLE_NAME
       || '
FIELDS TERMINATED BY \"'||DELIMITER||'\" OPTIONALLY ENCLOSED BY '''
       || CHR (34)
       || '''
TRAILING NULLCOLS ('
  FROM XXCM_SOUCRE_DATA_DEFINITION
 WHERE DATA_DEF_ID = "${dataDefId}"
UNION ALL
SELECT tab_cols
  FROM (
SELECT '    '||rpad(COL_NAME,50,' ')||' '||
       decode(substr(DATA_TYPE,1,4), 'DATE', 
                                     DATA_TYPE||' '''||FORMAT_MASK||''',', 
                                     '\"LTRIM(RTRIM(:'||COL_NAME||'))\",') tab_cols
from XXCM_SOUCRE_DATA_STRUCTURE
where data_def_id = "${dataDefId}"
 order by col_pos asc);
SPOOL OFF;"|sqlplus -s > /dev/null
echo "RECORD_ID                       SEQUENCE(MAX))" >> /u01/app/cm/files/snp/modules/srcdata/${dataDefId}.ctl
#sed -i '$s/,/ /' "/u01/app/cm/files/snp/modules/srcdata/${dataDefId}.ctl"
#echo ")" >> /u01/app/cm/files/snp/modules/srcdata/${dataDefId}.ctl
logFile="/u01/app/cm/files/logs/tmp/sqlldr_${dataDefId}_$$.log"
if [ -f "$fileName" ]; then
    dos2unix "$fileName"
    sqlldr USERID=$db_user/$db_password@$db_service CONTROL=/u01/app/cm/files/snp/modules/srcdata/${dataDefId}.ctl log=$logFile  DIRECT=TRUE 
    if [ -f $logFile ]; then
        logFileName=`basename $logFile`
        error=`grep -n "Rejected" $logFile|cut -f1 -d':'`
        if [ $error -gt 0 ]; then
            status="F"
        else
            status="C"
        fi
        echo "$db_user/$db_password@$db_service
              exec xxcm_util_pub.upload_exec_log("$execId",'"$logFileName"',"${dataDefId}",'LOAD_DATA','"${status}"');
              commit;
              exit;"|sqlplus -s > /dev/null
    fi
fi
rm -rf /u01/app/cm/files/snp/modules/srcdata/${dataDefId}.ctl
exit 0
