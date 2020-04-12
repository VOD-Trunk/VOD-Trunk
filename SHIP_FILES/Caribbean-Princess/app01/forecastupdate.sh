

echo >>/root/weatherupdate/setuserkey.log
date >>/root/weatherupdate/setuserkey.log


APIKEY=`curl -i -H "Content-Type: application/x-www-form-urlencoded" \
-X POST -d 'email=nacos@uievolution.com&pass=!uie1234' \
"http://admin.iptv.eudmdomain.hal.com/v2/private/auth?debug" 2>/dev/null |\
awk -F\" '/apikey/ {print $4}'`





echo >>/root/weatherupdate/refreshforecast.log
date >>/root/weatherupdate/refreshforecast.log
/usr/bin/curl -s -H "Authorization:${APIKEY}" "http://admin.iptv.kodmdomain.hal/location/private/refreshforecast" >>/root/weatherupdate/refreshforecast.log 2>&1
