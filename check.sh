#!/bin/bash


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/scripts

source ../config.txt

source ./logging.sh
source ./monitor.sh

DEBUG=0

for i in "$@"
do
	case $i in
		-d|--debug)
			DEBUG=1
    			shift 
		;;
		-q|--quiet)
			DEBUG=-1
    			shift 
		;;
		-h|--help)
			echo "-d | --debug  Always put the debug information"
			echo "-q | --quiet  Global overview even if errors"
			exit
		;;
		*)
		echo "$i : unknown option"
	esac
done


[ $DEBUG -eq 1 ] && uname -a
[ $DEBUG -eq 1 ] && cat /etc/redhat-release


message "users nodejs, couchdb and apache exists"
if
	grep -q "^nodejs" /etc/passwd &&
	grep -q "^couchdb" /etc/passwd &&
	grep -q "^apache" /etc/passwd
then
	ok
	[ $DEBUG -eq 1 ] && cat /etc/passwd
else
	error
	[ "$DEBUG" -ne -1 ] && cat /etc/passwd
fi	


message "node is present in /usr/bin/node"
whereis node | grep -q "/usr/bin/node"
printResult


message "node is version 5.x.x"
node -v | grep -q "v5"
printResult
printLs "/usr/local/node"

message "pm2 is running as user nodejs"
ps aux | grep -v "grep" | grep "PM2" | grep -q "nodejs"
printResult
printLs "/usr/local/pm2"
[ $DEBUG -eq 1 ] && echo "Checking pm2 status" && su nodejs -c "pm2 status"
[ $DEBUG -eq 1 ] && echo "Checking all the processes having pm2" && ps aux | grep pm2

message "roc-server is running on pm2"
su nodejs -c "pm2 status" | grep "roc-server" | grep -q "online"
printResult

message "roc-import is running on pm2"
su nodejs -c "pm2 status" | grep "roc-import" | grep -q "online"
printResult

message "couchDB is running as user couchdb"
ps aux | grep -v "grep" | grep -q "^couchdb"
printResult
printLs "/var/lib/couchdb"
printStatus "couchdb"

message "couchDB answer on http://127.0.0.1:5984/ and is version 1.6.1"
curl -sf http://127.0.0.1:5984/ | grep -q "1.6.1"
printResult

message "ROC answer on http://127.0.0.1/rest-on-couch/"
curl -sfL http://127.0.0.1/rest-on-couch/ > /dev/null
printResult

message "couchDB database demo-ir exists"
curl -sf http://127.0.0.1:5984/demo-ir/ | grep -q "demo-ir"
printResult

message "couchDB database demo-nmr exists"
curl -sf "http://127.0.0.1:5984/demo-nmr/" | grep -q "demo-nmr"
printResult

message "couchDB database demo-nmr2d exists"
curl -sf http://127.0.0.1:5984/demo-nmr2d/ | grep -q "demo-nmr2d"
printResult

message "apache (httpd) is running as user apache"
ps aux | grep -v "grep" | grep "^apache" | grep -q "httpd"
printResult
printLs "/etc/httpd/conf.d"
printStatus httpd

message "iptables is running"
if
	[ $REDHAT_RELEASE -eq 7 ]
then
	systemctl status iptables | grep -q "Active: active"
else
	service iptables status | grep -qv "Firewall is not running"
fi
printResult
printCat "/etc/sysconfig/iptables"
printStatus iptables
[ $? -ne 0 ] || [ $DEBUG -eq 1 ] && [ "$DEBUG" -ne -1 ] && ifconfig

message "$ROC_HOME_DIR folder exists"
[ -d "$ROC_HOME_DIR" ]
printResult
printLs "/usr/local/rest-on-couch"

checkDiskSpace
[ $? -ne 0 ] || [ $DEBUG -eq 1 ] && [ "$DEBUG" -ne -1 ] && df -h

freeMemory
[ $? -ne 0 ] || [ $DEBUG -eq 1 ] && [ "$DEBUG" -ne -1 ] && top -n1 -o %MEM

freeProc
[ $? -ne 0 ] || [ $DEBUG -eq 1 ] && [ "$DEBUG" -ne -1 ] && top -n1
