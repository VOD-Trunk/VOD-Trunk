

echo >>/root/weatherupdate/setuserkey.log
date >>/root/weatherupdate/setuserkey.log


APIKEY=`curl -i -H "Content-Type: application/x-www-form-urlencoded" \
-X POST -d 'email=nacos@uievolution.com&pass=!uie1234' \
"http://xicms-exm-svc.di.ocean.com/v2/private/auth?debug" 2>/dev/null |\
awk -F\" '/apikey/ {print $4}'`

echo >>/root/weatherupdate/refreshcurrent.log
date >>/root/weatherupdate/refreshcurrent.log
/usr/bin/curl -s -H "Authorization:${APIKEY}" "http://xicms-exm-svc.di.ocean.com/location/private/refreshcurrent" >>/root/weatherupdate/refreshcurrent.log 2>&1




