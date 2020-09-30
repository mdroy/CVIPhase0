#!/bin/bash
##################################################################
# Script Name   : schedule.sh
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

echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
select data_def_id||'|'||file_path||'|'||naming 
from XXCM_SOUCRE_DATA_DEFINITION dd
where exists (select null from xxcm_data_sources ds
where dd.ds_id = ds.ds_id
and ds.ds_type = 'FILE'
and ds.ds_sub_type = 'W')
and exists (select null from XXCM_MODULE_EXEC_DTLS e
             where e.module_id = dd.module_id
               and e.source = 'MOD_DEF'
               and status = 'W');
exit;"|sqlplus -s > /u01/app/cm/files/logs/tmp/sch_$$.log
cat /u01/app/cm/files/logs/tmp/sch_$$.log |wc -l
for i in `cat /u01/app/cm/files/logs/tmp/sch_$$.log`
do
    dataDefid=`echo $i|cut -f1 -d'|'`
    filePath=`echo $i|cut -f2 -d'|'`
    fileName=`echo $i|cut -f3 -d'|'`

    cd $filePath
    if ls $fileName 1> /dev/null 2>&1; then
        fileName=`ls $fileName`
	execId=`echo "$db_user/$db_password@$db_service
	SET PAGESIZE 0;
	set feedback off
	set heading off
	set verify off
	set echo off
	set tab off
	select exec_id
	from XXCM_MODULE_EXEC_DTLS
	where source = 'MOD_DEF'
        and status = 'W'
	and data_def_id = ${dataDefid};
	exit;"|sqlplus -s`
        execId=`echo $execId | xargs`       
        if [ ! -z $execId ] && [ ! -z "$fileName" ]; then	
	    echo "$db_user/$db_password@$db_service
	    exec xxcm_exec_pub.update_dtls($execId, xxcm_exec_pub.COMPLETED,'"${fileName}"');
	    exit;"|sqlplus -s 
        fi
    fi
done
rm -rf /u01/app/cm/files/logs/tmp/sch_$$.log
exit 0
