#!/bin/bash
HOST="$1"
PORT="$2"
USER="$3"
privateKey="$4"
passPhrase=`/u01/app/cm/scripts/bash/common/getDecPasswd.sh "$5"`
SOURCE_FILE="test_$$.txt"
echo "Test SFTP by Cloud Move" > $SOURCE_FILE

if [ -z "$5" ]; then

/usr/bin/expect <<EOF
spawn sftp -o StrictHostKeyChecking=no -i $privateKey $USER@$HOST
expect "sftp>"
send "put $SOURCE_FILE\r"
expect "sftp>"
send "rm $SOURCE_FILE\r"
expect "sftp>"
send "bye\r"
EOF

else

/usr/bin/expect <<EOF
spawn sftp -o StrictHostKeyChecking=no -i $privateKey $USER@$HOST
expect "Enter passphrase for key"
send "$passPhrase\r"
expect "sftp>"
end "put $SOURCE_FILE\r"
expect "sftp>"
send "rm $SOURCE_FILE\r"
expect "sftp>"
send "bye\r"
EOF

fi

if [ $? -eq 0 ]
then
    rm -rf $SOURCE_FILE
    exit 0
else
    rm -rf $SOURCE_FILE
    exit 1
fi
exit 0
