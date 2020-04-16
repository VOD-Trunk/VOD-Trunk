#!/bin/bash

echo >>/root/weatherupdate/setuserkey.log
date >>/root/weatherupdate/setuserkey.log

# Get current nacos apikey:
APIKEY=`curl -i -H "Content-Type: application/x-www-form-urlencoded" \
  -X POST -d 'email=nacos@uievolution.com&pass=!uie1234' \
  "http://admin.ap.ocean.com/v2/private/auth?debug" 2>/dev/null |\
  awk -F\" '/apikey/ {print $4}'`

echo >>/root/weatherupdate/refreshcurrent.log
date >>/root/weatherupdate/refreshcurrent.log
/usr/bin/curl -s -H "Authorization:${APIKEY}" "http://admin.ap.ocean.com/location/private/refreshcurrent" >>/root/weatherupdate/refreshcurrent.log 2>&1

#echo >>/root/weatherupdate/refreshforecast.log
#date >>/root/weatherupdate/refreshforecast.log
#/usr/bin/curl -s -H "Authorization:${APIKEY}" "http://admin.ap.ocean.com/location/private/refreshforecast" >>/root/weatherupdate/refreshforecast.log 2>&1
