#!/bin/bash -x

############################################################
# Do we even want to check yet?  Let's wait 15 minutes to
# make sure all the servers are up, first.  Mkay?
############################################################
# Read number of seconds uptime from /proc/uptime, and round
# it to an integer, if less than 900 seconds, just exit.
if (( `awk '{ printf "%.0f\n", $1 }' /proc/uptime` <= 900 )); then
  exit 0
fi

############################################################
# Starting variables:
############################################################
# App servers link paths:
MAPTILES=/apps/umr/shared/maptiles
UPLOADS=/apps/umr/shared/uploads
# Media servers link paths:
MEDIA=/home/wowza/media

# Am I Media or App server?
BOX=`hostname | egrep -o 'app|media'`

# And if I don't know what I am, exit...
if [ -z "${BOX}" ]; then
  echo "Cannot determine server type.  Exiting."
  exit 1
fi

# Prepair list of failed mount points.
FAILED=""

# Get current filesystem links state:
if [ `hostname | egrep -o 'app|media'` = "app" ]; then
  CURRENT_STATE=`ls -ld /apps/umr/shared/uploads | egrep -o 'm1a1|m2a1|m1a2|m2a2'`
elif [ `hostname | egrep -o 'app|media'` = "media" ]; then
  CURRENT_STATE=`ls -ld /home/wowza/media | egrep -o 'm1|m2'`
fi

############################################################
# Define functions:
############################################################
# App servers:
# Change from Media01 to Media02 storage
function app_m1_to_m2 {
  # Change mount to Media02 to READ ONLY...
  mount /nfs/m2 -o remount,ro
  # Let's not redo things if we have already done them
  # in a previous run...
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m1/m2/g'`
  if [ "${NEW_STATE}" != "${CURRENT_STATE}" ]; then
    # Change app links to use Media02 storage...
    rm -vf ${MAPTILES}        ${UPLOADS}
    ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
    ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}
  fi
} # End function app_m1_to_m2

# Change back from Media02 to Media01 storage
function app_m2_to_m1 {
  # Change app links to use Media01 storage...
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m2/m1/g'`
  if [ "${NEW_STATE}" != "${CURRENT_STATE}" ]; then
  rm -vf ${MAPTILES}        ${UPLOADS}
  ln -s /nfs/${NEW_STATE}/uploads   ${UPLOADS}
  ln -s /nfs/${NEW_STATE}/maptiles  ${MAPTILES}
  # Change mount to Media02 to READ WRITE...
  mount /nfs/m2 -o remount,rw
  fi
} # End function app_m2_to_m1

# Change from App01 to App02 storage
function app_a1_to_a2 {
  # If unison init script exists, stop unison...
  if [ -x "/etc/init.d/unison" ]; then
    monit stop unison || service unison stop
  fi
  # Change mount to App02 to READ ONLY...
  mount /nfs/a2 -o remount,ro
  # Change app links to use App02 storage...
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/a1/a2/g'`
  if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
    break 1
  fi
  rm -vf ${MAPTILES}        ${UPLOADS}
  ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
  ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}
} # End function app_m1_to_m2

# Change back from App02 to App01 storage
function app_a2_to_a1 {
  # Change mount to App02 to READ WRITE...
  mount /nfs/a2 -o remount,rw
  # Change app links to use App01 storage...
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/a2/a1/g'`
  if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
    break 1
  fi
  rm -vf ${MAPTILES}        ${UPLOADS}
  ln -s  /nfs/${NEW_STATE}/uploads  ${UPLOADS}
  ln -s  /nfs/${NEW_STATE}/maptiles ${MAPTILES}
    # If unison init script exists, start unison...
  if [ -x "/etc/init.d/unison" ]; then
    monit start unison || service unison start
  fi
} # End function app_m1_to_m2

# Media servers:
# Change from Media01 to Media02 storage
function med_m1_to_m2 {
  # If unison init script exists, stop unison...
  if [ -x "/etc/init.d/unison" ]; then
    monit stop unison || service unison stop
  fi
  # Change mount to Media02 to READ ONLY...
  mount /nfs/m2 -o remount,ro
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m1/m2/g'`
  if [ "${NEW_STATE}" != "${CURRENT_STATE}" ]; then
  # Change app links to use Media02 storage...
  rm -vf ${MEDIA}
  ln -s  /nfs/m2  ${MEDIA}
  fi
} # End function med_m1_to_m2

# Change back from Media02 to Media01 storage
function med_m2_to_m1 {
  # Change mount to Media02 to READ WRITE...
  mount /nfs/m2 -o remount,rw
  # Change app links to use Media01 storage...
  NEW_STATE=`echo "${CURRENT_STATE}" | sed -e 's/m2/m1/g'`
  if [ "${NEW_STATE}" = "${CURRENT_STATE}" ]; then
  rm -vf ${MEDIA}
  ln -s  /nfs/m1  ${MEDIA}
  # If unison init script exists, start unison...
  if [ -x "/etc/init.d/unison" ]; then
    monit start unison || service unison start
  fi
  fi
} # End function med_m1_to_m2

############################################################
# Monit status:
############################################################
# Check each remote NFS mount point: m1, m2, a1, a2
# If one is down, tell monit (exit 1)

if [ "$(basename $0)" = "storage-ck.sh" ]; then
  returnstatus = 0
  for i in m1 m2 a1 a2
  do
    # Setup a temporary counter counter...
    x=0
    # Check if it's NFS on this system or local:
    if ( egrep "\/nfs\/${i}.* nfs " /proc/mounts ); then
      # Test the mount point up to 3 times to see if it is hung:
      for y in {1..3}
      do
        timeout 1 stat /nfs/${i} || (( x++ ))
        # If test was good, exit with status 0
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

############################################################
# State detection:
############################################################
# Check each remote NFS mount point: m1, m2, a1, a2
# If one is down, consider failing it over...
# If all are down, consider we are broken, and don't failover...

for i in m1 m2 a1 a2
do
  # Setup a temporary counter counter...
  x=0
  # Check if it's NFS on this system or local:
  if ( egrep "\/nfs\/${i}.* nfs " /proc/mounts ); then
    # Test the mount point up to 3 times to see if it is hung:
    for y in {1..3}
    do
      timeout 1 stat /nfs/${i} || (( x++ ))
      # If test was good, leave the loop.
      if [ "${x}" -eq "0" ]; then
        break 1
      fi
    done
    
    if [ "${x}" -eq "3" ]; then
      FAILED=`echo ${FAILED} ${i}`
    fi
  fi
done

# App failovers
if [ `echo ${FAILED} | wc -w` -gt "0" -a "${BOX}" = "app" ]; then
  for i in ${FAILED}
  do
    # Re-get current filesystem links state for each loop:
    CURRENT_STATE=`ls -ld /apps/umr/shared/uploads | egrep -o 'm1a1|m2a1|m1a2|m2a2'`
    case $i in
      m1)
        app_m1_to_m2
        ;;
      m2)
        #app_m2_to_m1
        echo "/nfs/m2 is unavailable."
        ;;
      a1)
        app_a1_to_a2
        ;;
      a2)
        #app_a2_to_a1
        echo "/nfs/a2 is unavailable."
        ;;
      *)
        echo "An unknown error has occurred with this script."
        echo "Exiting with no action taken."
        exit 0
        ;;
    esac
  done
## App failback
#elif [ `echo ${FAILED} | wc -w` -eq "0" -a "${CURRENT_STATE}" != "m1a1" -a "${BOX}" = "app" ]; then
  #case ${CURRENT_STATE} in
    #m1a2)
      #app_a2_to_a1
      #;;
    #m2a1)
      #app_m2_to_m1
      #;;
    #m2a2)
      #app_m2_to_m1
      #app_a2_to_a1
      #;;
    #*)
      #echo "An unknown error has occurred with this script."
      #echo "Exiting with no action taken."
      #exit 
      #;;
  #esac
# Media failovers
elif [ `echo ${FAILED} | wc -w` -eq "1" -a "${BOX}" = "media" ]; then
  case ${FAILED} in
    m1)
      med_m1_to_m2
      ;;
    m2)
      #med_m2_to_m1
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
## Media failback
#elif [ `echo ${FAILED} | wc -w` -eq "0" -a "${CURRENT_STATE}" != "m1" -a "${BOX}" = "media" ]; then
  #case ${CURRENT_STATE} in
    #m2)
      #med_m2_to_m1
      #;;
    #*)
      #echo "An unknown error has occurred with this script."
      #echo "Exiting with no action taken."
      #;;
  #esac
elif [ `echo ${FAILED} | wc -w` -gt "2" ]; then
  echo "Detecting multiple network filesystems down, possible network"
  echo "outage.  Logging error to /var/log/fs-ha.log.  No further action"
  echo "will be taken at this time."
  # We could disable heartbeat and httpd on this host to pull it out of
  # rotation until network returns.  Need to discuss with the team about
  # that.
  echo "Maybe disable heartbeat on this host, as multiple network"
  echo "targets are unreachable."
fi

exit ${returnstatus}
