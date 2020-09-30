#!/bin/bash
##################################################################
# Script Name	: displayWallet.sh                                                                                             
# Description	: This script run bash scripts and return response                                                                               
# Args          :                                                                                           
# Author       	: Mithun D Roy                                               
# DateTime      : 10-APR-2020 21:04:00
###################################################################
echo "Test"
export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf
echo "$db_user/$db_password@$db_service
       delete from xxcm_ssl_certificates;
	   commit;
	   exit;"|sqlplus -s > /dev/null
orapki wallet display -wallet $db_wallet |grep -i "Subject:"|cut -f2 -d':'|sed -e 's/^[[:space:]]*//'|while read -r j
do
  IFS=',' read -ra ADDR <<< "$j"
  for i in "${ADDR[@]}"
  do
    fld=`echo "$i"| cut -f1 -d'='`
	case $fld in
      CN)
        vCN=`echo "$i"| cut -f2 -d'='|sed "s/'/''/g"`
        ;;
      OU)
        vOU=`echo "$i"| cut -f2 -d'='|sed "s/'/''/g"`
        ;;
      O)
        vO=`echo "$i"| cut -f2 -d'='|sed "s/'/''/g"`
        ;;
      C)	
        vC=`echo "$i"| cut -f2 -d'='|sed "s/'/''/g"`
        ;;	  
    esac
  done
  desc=`echo $j|sed "s/'/''/g"`
  echo "$db_user/$db_password@$db_service
        insert into xxcm_ssl_certificates (DESCRIPTION,CERTIFICATE_TYPE,COMMON_NAME,ORGANIZATIONAL_UNIT,ORGANIZATION_NAME,COUNTRY_NAME,CREATED_BY,LAST_UPDATED_BY)
		values ('"$desc"','T','"$vCN"','"$vOU"','"$vO"','"$vC"','SYSTEM','SYSTEM');
		commit;
		exit;"|sqlplus -s > /dev/null
done
exit 0
