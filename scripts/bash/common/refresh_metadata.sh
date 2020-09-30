#!/bin/bash
##################################################################
# Script Name   : refresh_metadata.sh
# Description   : This script run bash scripts and return response
# Args          : No Arguments expected
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf
export TMP_SQL_DATA="/tmp/sqltmp_$$.txt"

echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set verify off
set echo off
set tab off
SELECT ctl_file_id||'|'||ctl_file_name||'|'||interface_table_name
FROM XXCM_FBDI_CTL_FILES;
exit;"|sqlplus -s > $TMP_SQL_DATA

if [ -f $TMP_SQL_DATA ]
then
  for i in `cat $TMP_SQL_DATA`
  do
    idx=1
    ctlfileid=`echo $i|cut -f1 -d'|'`
    filename=`echo $i|cut -f2 -d'|'`
    tabname=`echo $i|cut -f3 -d'|'`
    echo "$db_user/$db_password@$db_service
          set feedback off
          set verify off
          set echo off 
          delete from XXCM_FBDI_COLUMNS where CTL_FILE_ID = "${ctlfileid}";
          commit;
          exit;"|sqlplus -s

    curl -s "https://www.oracle.com/webfolder/technetwork/docs/fbdi-20a/fbdi/controlfiles/$filename" > $filename
    startidx=`cat $filename|awk '{print $1}'|grep -ni "("|cut -f1 -d':'`
    endidx=`cat $filename|awk '{print $1}'|grep -ni ")"|cut -f1 -d':'`
    while [[ $startidx -le $endidx ]]
    do
        column=`cat $filename|awk '{print $1}'|head -$startidx|tail -1|tr ',' ' '|tr '(' ' '|tr ')' ' '|xargs`
        if [[ ! $column = --* ]]  &&  [[ ! -z "$column" ]]
        then
            echo "$db_user/$db_password@$db_service
                  set feedback off
                  set verify off
                  set echo off 
                  insert into XXCM_FBDI_COLUMNS (CTL_FILE_ID, TABLE_NAME, COLUMN_ORDER, COLUMN_NAME)
                  values ("${ctlfileid}",'"${tabname}"',"${idx}",'"${column}"');
                  commit;
                  exit;"|sqlplus -s
            let idx=idx+1
        fi
        let startidx=startidx+1
    done
  done
fi
rm -rf $TMP_SQL_DATA
exit 0

