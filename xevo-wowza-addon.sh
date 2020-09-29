#!/bin/bash
#
# Script Name:  xevo-wowza-addon.sh
# Purpose:      Xevo Hospitality Wowza Add-On's and Configuration Installation
# Author:       'Brandon Darbro' <bdarbro@xevo.com>
# License:      I can always use more money, but whatever.

# Define variables:
JAR="${1}"
# Wowza Current Path:
WOWZA="/usr/local/WowzaStreamingEngine"

# Functions:

## Function Name:   verlte
## Description:     Version check less than or equal to?
verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
} # End Function:   verlte

## Function Name:   verlte
## Description:     Version check less than?
verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
} # End Function:   verlt

# Execute section:

# Are we running as root?  If no, exit.
if [ "$EUID" -ne 0 ]; then
    echo "Please re-run as root.  Exiting."
    exit 255
fi

# Validate command line had only 1 argument...
# If the argument is "--help", has no argument, or more than one,
# show usage text.
if [ -z "${JAR}" -o -n "${2}" -o "${1}" = "--help" ]; then
    echo "Usage:"
    echo "xevo-wowza-addon.sh <jar-file-name>"
    echo "or"
    echo "xevo-wowza-addon.sh --help (for this info)"
    exit 1
fi

# Verify we have 'unzip' command installed:
which unzip > /dev/null 2>&1 || (echo "Cannot find unzip.  Exiting." ; exit 3) || exit 3

# Is Wowza Streaming Engine installed in /usr/local?
if [ ! -L "${WOWZA}" ]; then
    echo "Wowza is either not installed or the primary path is not a symbolic link, as it should be..."
    echo "Exiting."
    exit 2
fi

# Have Xevo Add-on's been installed already?
if [ ! -f "${WOWZA}/timestamp.txt" ]; then
    echo ""
    echo "Previous installation timestamp not found, assuming first install"
    echo "for this Wowza version..."
    echo ""
else
    # Version checking...
    md5old=$(md5sum "${WOWZA}/timestamp.txt")
    md5new=$(unzip -p "${JAR}" timestamp.txt | md5sum | sed 's/-/timestamp.txt/g')
    if [ "${md5old}" = "${md5new}" ]; then
        echo "Jar ${JAR} has already been applied to this Wowza version,"
        echo "the timestamp.txt files match.  If you really wish to re-apply"
        echo "this version of the Jar, please remove file:"
        echo "${WOWZA}/timestamp.txt and re-run this installer."
        exit 255
    else
        verold=$(awk '/^Version:/ {print $NF}' "${WOWZA}/timestamp.txt" | sed 's/-.*$//')
        vernew=$(unzip -p "${JAR}" timestamp.txt | awk '/^Version:/ {print $NF}' | sed 's/-.*$//')
        verlte "${verold}" "${vernew}" || (echo "You are attempting to install an older version.  Exiting."; exit 5) || exit 5
    fi
fi

# List what we intend to install and ask if ok:
echo ""
echo "This would install the following files into the current Wowza installation..."
echo ""
(for file in $(unzip -l ${JAR} timestamp.txt conf/*.??? applications/*.??? bin/*.??? -x */.gitignore | awk '/[0-9]  20/ {print $NF}')
do
    if [ -f "${WOWZA}/${file}" ]; then
        echo "Updating: ${WOWZA}/${file}"
    else
        echo "Installing: ${WOWZA}/${file}"
    fi
done ) | column -t | sort

# Offer one final chance to stop or do the install...
while true
do
    echo ""
    read -r -p "Do you agree to continue this installation [y/n]?" x
    case $x in
        [yY][eE][sS]|[yY])
            echo "Proceding with installation..."
            unzip -o "${JAR}" timestamp.txt conf/* applications/* bin/* -x */.gitignore -d ${WOWZA} &&
            cp -v "${JAR}" ${WOWZA}/lib
            echo "Done, please restart WowzaStreamingEngine."
            exit 0
            ;;
        [nN][oO]|[nN])
            echo "Exiting with no changes made."
            exit 0
            ;;
        *)
        echo "Yes or no, please..."
        ;;
    esac
done
exit