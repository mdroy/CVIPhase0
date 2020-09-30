#!/bin/bash
HOST="$1"
PORT="$2"
USER="$3"
PASSWORD=`/u01/app/cm/scripts/bash/common/getDecPasswd.sh "$4"`
SOURCE_FILE="test_$$.txt"
echo "Test SFTP by Cloud Move" > $SOURCE_FILE

/usr/bin/expect <<EOF
spawn sftp -o StrictHostKeyChecking=no $USER@$HOST
expect "password:"
send "$PASSWORD\r"
expect "sftp>"
send "put $SOURCE_FILE\r"
expect "sftp>"
send "rm $SOURCE_FILE\r"
expect "sftp>"
send "bye\r"
EOF

if [ $? -eq 0 ]
then
    rm -rf $SOURCE_FILE
    exit 0
else
    rm -rf $SOURCE_FILE
    exit 1
fi
exit 0
