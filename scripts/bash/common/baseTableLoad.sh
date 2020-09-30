#!/bin/bash
##################################################################
# Script Name   : baseTableLoad.sh
# Description   : This script import data to Interface tables
# Args          : $1 --> Instance ID
#                 $2 --> File to be Imported
#                 $3 --> UCM Account
# Author        : Rohit Agrawal
# DateTime      : 13-MAY-2020 17:00:00
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
logFile="/u01/app/cm/files/logs/tmp/bload_$$.log"

connString=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set linesize 3000
set verify off
set echo off
set tab off
select INSTANCE_URL||'/fscmService/ErpIntegrationService?WSDL|'||
USER_NAME||'|'||
PASSWORD
from XXCM_CLOUD_ERP_INSTANCES
where instance_id = "${INST_ID}";
exit;"|sqlplus -s`

URL=`echo $connString|awk -F"|" '{print $1}'`
USERNAME=`echo $connString|awk -F"|" '{print $2}'`
PASSWORD=`echo $connString|awk -F"|" '{print $3}'`

export METADATA_ID="$2"
export execId="$3"

connString=`echo "$db_user/$db_password@$db_service
SET PAGESIZE 0;
set feedback off
set heading off
set linesize 3000
set verify off
set echo off
set tab off
select ESS_JOB
from XXCM_ERP_CLOUD_METADATA
where metadata_id = "${METADATA_ID}";
exit;"|sqlplus -s`

JOB_PKG=`echo $connString|cut -f1 -d';'`
JOB_DEF=`echo $connString|cut -f2 -d';'`

cat > "/u01/app/cm/files/logs/tmp/I_${METADATA_ID}_${execId}.xml" <<EOF
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
   <soapenv:Header/>
   <soapenv:Body>
      <typ:submitESSJobRequest>
         <typ:jobPackageName>${JOB_PKG}</typ:jobPackageName>
         <typ:jobDefinitionName>${JOB_DEF}</typ:jobDefinitionName>
      </typ:submitESSJobRequest>
   </soapenv:Body>
</soapenv:Envelope>
EOF

curl -sS --user $USERNAME:$PASSWORD --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/submitESSJobRequest" --data @"/u01/app/cm/files/logs/tmp/I_${METADATA_ID}_${execId}.xml" $URL -k -o "/u01/app/cm/files/logs/tmp/O_${METADATA_ID}_${execId}.xml" >> $logFile

if [ -f "/u01/app/cm/files/logs/tmp/O_${METADATA_ID}_${execId}.xml" ]; then
    echo "$db_user/$db_password@$db_service
          exec xxcm_util_pub.upload_exec_log("$execId",'"O_${METADATA_ID}_${execId}.xml"',NULL,'LOAD','C');
          commit;
          exit;"|sqlplus -s >> $logFile
fi
dos2unix "/u01/app/cm/files/logs/tmp/O_${METADATA_ID}_${execId}.xml" >> $logFile 2>&1
LD_REQ_ID=`cat "/u01/app/cm/files/logs/tmp/O_${METADATA_ID}_${execId}.xml"|awk -F"result" '{print $2}'|awk -F">" '{print $2}'|awk -F"<" '{print $1}'|xargs`
echo $LD_REQ_ID >> $logFile
echo $LD_REQ_ID
if [ ! -z $LD_REQ_ID ]; then
    echo "$db_user/$db_password@$db_service
          update XXCM_MODULE_EXEC_DTLS
             set system_id = '"${LD_REQ_ID}"',
                 status = 'C',
                 end_time = sysdate
           where exec_id = "${execId}";
          exit;"|sqlplus -s >> $logFile
fi
exit 0
