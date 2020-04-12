

echo >>/root/weatherupdate/refreshcurrent.log
date >>/root/weatherupdate/refreshcurrent.log
/usr/bin/curl -s "http://admin.britanniavod.carnivaluk.com/location/private/refreshcurrent" >>/root/weatherupdate/refreshcurrent.log 2>&1




