#!/bin/bash
nfs_a1=`./bin/health_check.sh | sed -n '/Disk Space/,/Load Balancer Rotation/p' | grep -w -m 1 "\/nfs\/a1" | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`
nfs_a2=`./bin/health_check.sh | sed -n '/Disk Space/,/Load Balancer Rotation/p' | grep -w -m 1 "\/nfs\/a2" | tr -s ' ' | cut -d " " -f 7 | cut -d "%" -f 1`

if [ $nfs_a1 -gt 90 ]
then
	find /home/netsvcs/sqlback/ -name "*" -ctime +30 -exec rm {} \;
fi

if [ $nfs_a2 -gt 90 ]
then
	ssh app02 'find /home/netsvcs/sqlback/ -name "*" -ctime +30 -exec rm {} \;'
fi

