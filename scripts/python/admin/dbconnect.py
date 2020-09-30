import sys
import cx_Oracle

db = None
user = str(sys.argv[1])
passwd = str(sys.argv[2])
hostname = str(sys.argv[3])
port = str(sys.argv[4])
svcname = str(sys.argv[5])
try:
    db = cx_Oracle.connect(user, passwd, hostname + ':' + port + '/' + svcname)
    print(db.version)
    db.close()
except cx_Oracle.DatabaseError as e:
    error, = e.args
    if error.code == 1017:
        print('Please check your credentials.')
        # sys.exit()?
    else:
        print('Database connection error')
