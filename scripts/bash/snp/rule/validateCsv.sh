#!/bin/bash
##################################################################
# Script Name   : validateCsv.sh
# Description   : This script validates a given CSV data file
# Args          : $f --> file reference
# Author        : Mithun D Roy
# DateTime      : 10-APR-2020 21:04:00
###################################################################
function checkColCount {
	if [ "$header_row" = "Y" ]; then
	    printf "First row of the data file identified as header\n" >> $logFile
		printf "Checking all records including header for $column_count columns\n" >> $logFile
		awk -v cnt=$column_count -v delim=$delimiter 'BEGIN{FS=OFS=delim} NF!=cnt {print "Not enough fields at line number " NR; exit 1}' $srcFile  >> $logFile
	fi	
}

function rowLevelChecks {
	n=`jq '.columns | length' $confFile`
	ucol=""
	for (( i=1; i<=$n; i++ ))
	do
		((colPos=i-1))
		colName=`cat $confFile |jq ".columns[$colPos].column_name"|cut -f2 -d'"'`
		dataType=`cat $confFile |jq ".columns[$colPos].data_type"|cut -f2 -d'"'`
		dataLen=`cat $confFile |jq ".columns[$colPos].data_length"`
		notNull=`cat $confFile |jq ".columns[$colPos].nullable"|cut -f2 -d'"'`
		unique=`cat $confFile |jq ".columns[$colPos].unique"|cut -f2 -d'"'`
		formatMask=`cat $confFile |jq ".columns[$colPos].format_mask"|cut -f2 -d'"'`
		
		printf "Performing data quality checks for COLUMN : $colName \n"  >> $logFile
		if [ "$notNull" = "N" ]; then
			printf " --> Checking for empty values in $colName \n"  >> $logFile
			gawk -v col="$i" -F"$delimiter"  'FNR>1 {if ($col == "") print "  ----> Error:Column value for Line", NR, " is NULL"; exit 1}' $srcFile  >> $logFile
		fi	
		
		if [ "$dataLen" -gt 0 ]; then
			printf " --> Checking for data length in $colName (should not cross $dataLen)\n"  >> $logFile
			gawk -v col="$i"  -v Len="$dataLen" -F"$delimiter" 'FNR>1 {if (length($col) > Len) print "  ----> Error:Column value for Line", NR, "is OVERSIZED"; exit 1}' $srcFile  >> $logFile
		fi	
		
		if [ "$dataType" = "NUMBER" ]; then
			printf " --> Checking for numeric data in $colName (excluding empty values)\n"  >> $logFile
			gawk -v col="$i" -F"$delimiter" 'FNR>1 {if (($col=="") || ($col+0 != $col)) print "  ----> Error:Column value for Line", NR, "Non numeric";}' $srcFile  >> $logFile
		elif [ "$dataType" = "DATE" ]; then
			if [ "$formatMask" != "null" ]; then
				echo " --> Checking date format as $formatMask in $colName (excluding empty values)"  >> $logFile
				python /u01/app/cm/scripts/python/snp/rule/fileCheck.py "$srcFile" $i "$formatMask" >> $logFile
			fi	
		fi
		
		if [ "$unique" = "Y" ]; then
			ucol=`echo ${ucol}'$'$i`
		fi
	done
	
	printf "Validating file for duplicate keys as per uniqueness definition\n" >> $logFile
	awk -F"$delimiter" -v fl="$ucol" '{print $fl}' $srcFile|awk 'a[$1]++ {print "  ----> Error:Duplicate key found at Line number ", NR; exit 1}'  >> $logFile
}

if [ $# -ne 4 ]; then
    printf "\nInvalid parameter value\n"
    exit 1
else
    ruleId="$1"
    fileName="$2"
    dataDefId="$3"
    execId="$4"
fi

export ORACLE_SID=XE
export ORAENV_ASK=NO
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export PATH=$PATH:$ORACLE_HOME/bin
source /u01/app/cm/config/xedb.conf

export logFile=/u01/app/cm/files/logs/tmp/stdchk_${ruleId}_$$.log
# Creating empty log file if not present
if [ -f $logFile ]; then
	touch $logFile
fi
	
# Check for valid file reference
srcFile="/u01/app/cm/files/snp/modules/srcdata/${fileName}"

if [ ! -f "${srcFile}" ]; then
    printf "Error:Invalid source data file reference\n" > $logFile
    exit 1
else
    dos2unix $srcFile
fi
printf "Source data file to be checked : $srcFile\n" >> $logFile

printf "Logs for this session can be found at : $logFile\n" >> $logFile
# Check for config file and source if exists
confFile="/u01/app/cm/files/snp/rule/${ruleId}.json"
if [ -f $confFile ]; then
	export column_count=`jq .column_count $confFile`
	export header_row=`jq .header_row $confFile|cut -f2 -d'"'`
	export delimiter=`jq .delimiter $confFile|cut -f2 -d'"'`
fi  
printf "Data quality check configuration file : $confFile\n\n" >> $logFile

dt=`date`
printf "Please note, this program reports only the first identified failures.\n" >> $logFile
printf "Once corrected you need to recheck for further issues.\n\n" >> $logFile
printf "Starting quality check process at $dt\n" >> $logFile
printf "+-----------------------------------------------------+\n\n" >> $logFile
checkColCount
rowLevelChecks
dt=`date`
printf "\n+-----------------------------------------------------+\n" >> $logFile
printf "Data quality check ends at $dt\n" >> $logFile
fileName=`basename $logFile`
status=`grep -ni "Error:" $logFile|wc -l`
if [ $status -gt 0 ]; then
   status="F"
else
   status="C"
fi
echo "$db_user/$db_password@$db_service
      exec xxcm_util_pub.upload_exec_log("$execId",'"$fileName"',"${dataDefId}",'STD_CHK','"$status"');
      commit;
      exit;"|sqlplus -s > /dev/null
echo "Success"
exit 0

