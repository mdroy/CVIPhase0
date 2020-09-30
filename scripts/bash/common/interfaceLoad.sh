#!/bin/bash
##################################################################
# Script Name   : interfaceLoad.sh
# Description   : This script import data to Interface tables
# Args          : $1 --> Instance ID
#		  $2 --> File to be Imported
#		  $3 --> UCM Account
# Author        : Rohit Agrawal
# DateTime      : 13-MAY-2020 17:00:00
###################################################################
if [ $# -ne 4 ]; then
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
logFile="/u01/app/cm/files/logs/tmp/iload_$$.log"

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

export UCM_REQ_ID="$2"
export IMP_PRC_ID="$3"
export execId="$4"
JOB_PKG="/oracle/apps/ess/financials/commonModules/shared/common/interfaceLoader/"
JOB_DEF="InterfaceLoaderController"

cat > "/u01/app/cm/files/logs/tmp/I_${UCM_REQ_ID}_${IMP_PRC_ID}.xml" <<EOF
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
   <soapenv:Header/>
   <soapenv:Body>
      <typ:submitESSJobRequest>
         <typ:jobPackageName>$JOB_PKG</typ:jobPackageName>
         <typ:jobDefinitionName>$JOB_DEF</typ:jobDefinitionName>
         <!--Zero or more repetitions:-->
         <typ:paramList>$IMP_PRC_ID</typ:paramList>
         <typ:paramList>$UCM_REQ_ID</typ:paramList>
         <typ:paramList>N</typ:paramList>
         <typ:paramList>N</typ:paramList>
         <typ:paramList>#NULL</typ:paramList>
      </typ:submitESSJobRequest>
   </soapenv:Body>
</soapenv:Envelope>
EOF

curl -sS --user $USERNAME:$PASSWORD --header "Content-Type: text/xml;charset=UTF-8" --header "SOAPAction:http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/submitESSJobRequest" --data @"/u01/app/cm/files/logs/tmp/I_${UCM_REQ_ID}_${IMP_PRC_ID}.xml" $URL -k -o "/u01/app/cm/files/logs/tmp/0_${UCM_REQ_ID}_${IMP_PRC_ID}.xml" >> $logFile

if [ -f "/u01/app/cm/files/logs/tmp/0_${UCM_REQ_ID}_${IMP_PRC_ID}.xml" ]; then
    echo "$db_user/$db_password@$db_service
          exec xxcm_util_pub.upload_exec_log("$execId",'"0_${UCM_REQ_ID}_${IMP_PRC_ID}.xml"',NULL,'IMPORT','C');
          commit;
          exit;"|sqlplus -s >> $logFile
fi
dos2unix "/u01/app/cm/files/logs/tmp/0_${UCM_REQ_ID}_${IMP_PRC_ID}.xml" >> $logFile 2>&1
IMP_REQ_ID=`cat "/u01/app/cm/files/logs/tmp/0_${UCM_REQ_ID}_${IMP_PRC_ID}.xml"|awk -F"result" '{print $2}'|awk -F">" '{print $2}'|awk -F"<" '{print $1}'|xargs`
echo $IMP_REQ_ID >> $logFile
echo $IMP_REQ_ID
if [ ! -z $IMP_REQ_ID ]; then
    echo "$db_user/$db_password@$db_service
          update XXCM_MODULE_EXEC_DTLS
             set system_id = '"${IMP_REQ_ID}"',
                 status = 'C',
                 end_time = sysdate
           where exec_id = "${execId}";
          exit;"|sqlplus -s >> $logFile
fi
exit 0
