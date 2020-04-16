#!/bin/bash

# /usr/local/bin/wowperf.sh
# For Wowza Media Servers

# Script to check the timing results of the last 5000 calls
# to wowza that got a 200 response.  Report it in a pretty table.
# Brandon Darbro - UIE

# Requires a specific logging configuration in
# /etc/httpd/conf/httpd.conf.  The following lines
# have an added pound sign in front for commenting
# here.  If using these lines below in your apache
# config, remember to remove the first # of each line:

#---- Below this line -----
#LogFormat "%h %l %u %t %T %D \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
#LogFormat "%h %l %u %t %T %D \"%r\" %>s %b" common
#LogFormat "%{Referer}i -> %U" referer
#LogFormat "%{User-agent}i" agent
#CustomLog logs/access_log combined
#---- Above this line -----

(echo "Seconds Number-of-Requests Percentage"
 cat /var/log/httpd/access_log |\
 awk '{ print $6 " " $11 }' |\
 grep " 200" | tail -n 5000 | sort -n | uniq -c |\
 sed -e 's/ 200//g' | awk '{ t = $1; $1 = $2; $2 = t; print; }' |\
 while read -r -a line
   do
     line[2]=`echo "scale=2; ${line[1]}*100/5000" | bc -l | sed -e 's/^\./00./g'`
     echo "${line[0]} ${line[1]} ${line[2]}%"
   done) | column -t | sed -e 's/\b[1-9]\b\./0&/g'

