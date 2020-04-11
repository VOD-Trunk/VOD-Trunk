







if (( `awk '{ printf "%.0f\n", $1 }' /proc/uptime` <= 900 )); then
exit 0
fi





MAPTILES=/apps/umr/shared/maptiles
UPLOADS=/nfs/uploads

MEDIA=/home/wowza/media


BOX=`hostname | egrep -o 'app|media'`


if [ -z "${BOX}" ]; then
echo "Cannot determine server type.  Exiting."
exit 1
fi


FAILED=""


if [ `hostname | egrep -o 'app|media'` = "app" ]; then
CURRENT_STATE=`ls -ld /nfs/uploads | egrep -o 'm1a1|m2a1|m1a2|m2a2'`
elif [ `hostname | egrep -o 'app|media'` = "media" ]; then
CURRENT_STATE=`ls -ld /home/wowza/media | egrep -o 'm1|m2'`
fi






function app_m1_to_m2 {

mount /nfs/m2 -o remount,ro


NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m1/m2/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi

rm -vf ${MAPTILES}        ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}
} 


function app_m2_to_m1 {

NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m2/m1/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi
rm -vf ${MAPTILES}        ${UPLOADS}
ln -s /nfs/${NEW_STATE}/uploads   ${UPLOADS}
ln -s /nfs/${NEW_STATE}/maptiles  ${MAPTILES}

mount /nfs/m2 -o remount,rw
} 


function app_a1_to_a2 {

if [ -x "/etc/init.d/unison" ]; then
monit stop unison || service unison stop
fi

mount /nfs/a2 -o remount,ro

NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/a1/a2/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi
rm -vf ${MAPTILES}        ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}
} 


function app_a2_to_a1 {

mount /nfs/a2 -o remount,rw

NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/a2/a1/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi
rm -vf ${MAPTILES}        ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}

if [ -x "/etc/init.d/unison" ]; then
monit start unison || service unison start
fi
} 



function med_m1_to_m2 {

if [ -x "/etc/init.d/unison" ]; then
monit stop unison || service unison stop
fi

mount /nfs/m2 -o remount,ro
NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m1/m2/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi

rm -vf ${MEDIA}
ln -s  /nfs/m2  ${MEDIA}
} 


function med_m2_to_m1 {

mount /nfs/m2 -o remount,rw

NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m2/m1/g'`
if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
break 1
fi
rm -vf ${MEDIA}
ln -s  /nfs/m1  ${MEDIA}

if [ -x "/etc/init.d/unison" ]; then
monit start unison || service unison start
fi
} 







if [ "$(basename $0)" = "storage-ck.sh" ]; then
returnstatus = 0
for i in m1 m2 a1 a2
do

x=0

if ( egrep "\/nfs\/${i}.* nfs " /proc/mounts ); then

for y in {1..3}
do
timeout 1 stat /nfs/${i} || (( x++ ))

if [ "${x}" -eq "0" ]; then
break 1 
fi
done

if [ "${x}" -eq "3" ]; then
FAILED=`echo ${FAILED} ${i}`
returnstatus=1 
fi
fi
done
exit ${returnstatus}
fi








for i in m1 m2 a1 a2
do

x=0

if ( egrep "\/nfs\/${i}.* nfs " /proc/mounts ); then

for y in {1..3}
do
timeout 1 stat /nfs/${i} || (( x++ ))

if [ "${x}" -eq "0" ]; then
break 1
fi
done

if [ "${x}" -eq "3" ]; then
FAILED=`echo ${FAILED} ${i}`
fi
fi
done


if [ `echo ${FAILED} | wc -w` -gt "0" -a "${BOX}" = "app" ]; then
for i in ${FAILED}
do

CURRENT_STATE=`ls -ld /nfs/uploads | egrep -o 'm1a1|m2a1|m1a2|m2a2'`
case $i in
m1)
app_m1_to_m2
;;
m2)

echo "/nfs/m2 is unavailable."
;;
a1)
app_a1_to_a2
;;
a2)

echo "/nfs/a2 is unavailable."
;;
*)
echo "An unknown error has occurred with this script."
echo "Exiting with no action taken."
exit 0
;;
esac
done




















elif [ `echo ${FAILED} | wc -w` -eq "1" -a "${BOX}" = "media" ]; then
case ${FAILED} in
m1)
med_m1_to_m2
;;
m2)

echo "/nfs/m1 is unavailable."
;;
a1)
exit 0
;;
a2)
exit 0
;;
*)
echo "An unknown error has occurred with this script."
echo "Exiting with no action taken."
;;
esac











elif [ `echo ${FAILED} | wc -w` -gt "2" ]; then
echo "Detecting multiple network filesystems down, possible network"
echo "outage.  Logging error to /var/log/fs-ha.log.  No further action"
echo "will be taken at this time."



echo "Maybe disable heartbeat on this host, as multiple network"
echo "targets are unreachable."
fi

exit ${returnstatus}
