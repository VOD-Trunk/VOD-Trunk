





echo >>/root/weatherupdate/refreshforecast.log
date >>/root/weatherupdate/refreshforecast.log
/usr/bin/curl -s "http://admin.britanniavod.carnivaluk.com/location/private/refreshforecast" >>/root/weatherupdate/refreshforecast.log 2>&1
