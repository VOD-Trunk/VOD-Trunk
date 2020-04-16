#!/bin/bash

trap ctrl_c INT

SERVER_NAME=`hostname | awk -F. '{ print $1 }' | tr '[:lower:]' '[:upper:]'`

function ctrl_c() {
  echo ""
  echo "CTRL-C Disabled.  Please answer Y or N."
  echo ""
  powerdown
} # End function ctrl_c

function powerdown() {
  echo "*** WARNING ***"
  echo ""
  echo "You are about to shut down this server, ${SERVER_NAME}"
  echo -n "Do you really wish to do this (Y/N) ? "
  read RESPONSE
  case ${RESPONSE} in
    [yY] | [yY][eE][sS] )
      echo "Initiating shutdown..."
      #echo "sudo /sbin/shutdown -hy now"
      sudo shutdown -hy now
      ;;
    [nN] | [n|N][o|O] )
      echo "Logging out of the system WITHOUT shutdown."
      exit 0
      ;;
    *)
      echo ""
      echo "Invalid response:  Please answer Y or N."
      powerdown
      ;;
  esac
} # End function powerdown

powerdown
