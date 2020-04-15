#!/bin/bash

# Check usage for function of script.
# Most variables for portability should be modifiable below.

# Chris Jacobs
# Sept 25, 2008
# Updated for EC2 - John Cary
# April 07, 2009

ServerXML="/etc/tomcat7/sites-available/*.xml"
TCLog="/var/log/tomcat7/catalina.out"
TCLogStartupStr="INFO: Server startup in"
TCConf="/etc/tomcat7/Catalina"

usage()
{
cat << EOF

  usage: $0 -v [sitename] [options]...

  This script deploys new war files by:
    1 Deleting old context contents and war file
    2 Unzipping new war into context
    3 Copying new war next to context
    4 Clearing the context cache
    5 Restarting Tomcat5 (optional)

  OPTIONS:
    -h --help  Show this message and exit

    -v         Sitename
                 Any string matching one instance of an AppBase
                 parameter defined in: $ServerXML
               ** REQUIRED **
    -c         Context name
                 Defined as '_' or 'root' will be set to be 'ROOT'
                 Left unset will be set to War name.
    -w         WAR file to deploy
                 Left unset, script will search for matching
                 file to provided sitename.  If more than one
                 match, script will end.
                 Searches in order: pwd then ~.
    -n         Context is new : Skip checks for existing paths.
    -t         Touches ROOT.xml file in conf.
                 If VHost configured with autoDeploy="True" this
                 causes Tomcat to redeploy the context.
    -r         Restart Tomcat5.
                 If set with -m script will quit.
    -m         Do not restart Tomcat5 and don't prompt.
                 Presumably there are more contexts to deploy.
                 If set with -r script will quit.
    -l         Timeout limit waiting for Tomcat log to indicate
                 server startup (seconds). Default: 30
    -k         Timeout limit while force killing tomcat.
                 This is after /etc/init.d/tomcat7 has stopped.
                 Seconds.  Default: 30
    -q         Quiet.  Prompts will still be required.

  If neither of -r or -m options are present, you'll be prompted
  on whether to restart Tomcat5.

  These options may appear in any order, or combined.

  * You may be prompted for sudo password; root access is required.

  Examples:
    $0 -v uieme
    $0 -v uieme -c _ -w ~/uieme.war -nr
    $0 -nr -c root -v uieme -w ~/uieme.war
    $0 -v uieme -rq
    $0 -v www.uieme.com -c ROOT -w /home/netsvcs/uieme.war -n -r

EOF
}

# --------------------------------------------------
# Attempts to locate war file at $1 matching:
# *sitename*.war
# --------------------------------------------------
CheckForWarAt()
{
  WarFileSearch=`ls -1 $1/*$InSitename*.war 2>/dev/null`
  WarMatches=`echo $WarFileSearch | awk '{ print NF }'`
  if [ "$WarMatches" = "" ] ; then WarMatches="0" ; fi

  case $WarMatches in
    0  ) echo "--none--"                     ;;
    1  ) echo "$WarFileSearch"               ;;
    *  ) erecho ":: More than one match found for *$InSitename*.war in $1" ;
         erecho ":: Please use -w [warfile]"
         echo "TooDamnMany"                  ;;
  esac
}

# --------------------------------------------------
# Makes scripting easier - make the decision here
# not everywhere in the script.
# This excludes errors and required prompts.
# --------------------------------------------------
qecho()
{
  if [ "$NoPrompts" != "1" ] ; then eecho "$*" ; fi
}

# --------------------------------------------------
# Allows me to format echo statements as I choose.
# Currently only prefixing time.
# --------------------------------------------------
eecho()
{
  echo `date +%T` :"$*"
}

# --------------------------------------------------
# Echoes Errors using desired format to /dev/stderr
# --------------------------------------------------
erecho()
{
  echo "`date +%T` :$*" > /dev/stderr
}


# --------------------------------------------------
# Parse Command Line Arguments
# --------------------------------------------------

while getopts ":qv:c:w:nrmtl:k:" OPTION
do
  case $OPTION in
    q    )  NoPrompts="1";     ;;
    v    )  Sitename=$OPTARG;  ;;
    c    )  Context=$OPTARG;   ;;
    w    )  War=$OPTARG;       ;;
    n    )  NewContext="1";    ;;
    r    )  RestartTC="1";     ;;
    m    )  NoRestartTC="1";   ;;
    t    )  TouchConf="1";     ;;
    l    )  TimeLimit=$OPTARG; ;;
    k    )  KillLimit=$OPTARG; ;;
    ? | h)  usage; exit        ;;
  esac
done

# --------------------------------------------------
# Provided sitename is important to other options as well
# Sitename will end up as the /full/ sitename, so we need
# to keep a copy.
# --------------------------------------------------

InSitename="$Sitename"

# --------------------------------------------------
# Inform user of provided options.
# Not 100% necessary, but I prefer it.
# --------------------------------------------------

if [ "$NoPrompts" != "1" ] ; then
  echo "`date +%T`    : Command Line Args"
  if [ "$Sitename"    != "" ] ; then echo "  Sitename    - $Sitename"    ; fi
  if [ "$Context"     != "" ] ; then echo "  Context     - $Context"     ; fi
  if [ "$War"         != "" ] ; then echo "  War         - $War"         ; fi
  if [ "$NewContext"  != "" ] ; then echo "  NewContext  - $NewContext"  ; fi
  if [ "$RestartTC"   != "" ] ; then echo "  RestartTC   - $RestartTC"   ; fi
  if [ "$NoRestartTC" != "" ] ; then echo "  NoRestartTC - $NoRestartTC" ; fi
  if [ "$TouchConf"   != "" ] ; then echo "  TouchConf   - $TouchConf"   ; fi
  if [ "$TimeLimit"   != "" ] ; then echo "  TimeLimit   - $TimeLimit"   ; fi
  if [ "$KillLimit"   != "" ] ; then echo "  KillLimit   - $KillLimit"   ; fi
fi

qecho "------------------------------"

# --------------------------------------------------
# Start checking for valid args
# --------------------------------------------------

qecho " Checking options ..."

# -----------------------------------
# We can't both restart and not
# restart tomcat...
if [ "$RestartTC" = "1" -a "$NoRestartTC" = "1" ] ; then
  erecho ": Options: -r (Restart Tomcat) and"
  erecho ":          -m (Do Not Restart Tomcat)"
  erecho ": Cannot both be used"
  exit
fi

# -----------------------------------
# $Sitename option provided?

if [ "$Sitename" = "" ] ; then
  erecho "-v [sitename] required"
  erecho
  usage
  exit
fi

# -----------------------------------
# $Sitename exist once in $ServerXML?

appBase=`grep -i $Sitename $ServerXML | grep -i appbase | awk -F \" '{ print $2 }'`
NumappBaseMatches=`echo $appBase | awk '{ print NF }'`

if [ "$NumappBaseMatches" != "1" ] ; then
  erecho " Bad sitename: $Sitename"
  erecho " Matching not exactly one appBase in $ServerXML:"
  erecho " Begin match results: ---------------"
  if [ $NumappBaseMatches -gt 1 ] ; then erecho " $appBase" ; fi
  erecho " End match results ------------------"
  exit
fi
qecho ": appBase for $Sitename defined in $ServerXML once: $appBase"

# -----------------------------------
# If $Sitename occurs more than once
# in $appBase, attempting to locate
# the exact $Sitename is 'fuzzy'

SitenameInAppBase=`echo $appBase | awk -F \/ '{for(i=1;i <=NF;i++) print $i }' | grep -i $Sitename`
NumSitenameInAppbase=`echo "$SitenameInAppBase" | grep -ic $Sitename`

if [ "$NumSitenameInAppbase" != "1" ] ; then
  erecho " $Sitename occurs more than once in $appBase path"
  erecho " This leads to undesired 'fuzziness'"
  exit
else
  qecho ": Sitename occurs once in $appBase path"
fi
Sitename=$SitenameInAppBase
qecho ": Full Sitename is $Sitename"

# -----------------------------------
# If $War unset, look for it in pwd
# and ~ matching *$InSitename*.war

if [ "$War" = "" ] ;  then
  qecho ": War unset - Checking $PWD for war file matching *$InSitename*.war"
  War=`CheckForWarAt $PWD`
  if [ "$War" = "TooDamnMany" ] ; then exit; fi
  if [ "$War" = "--none--" ] ; then
    qecho ":: No matches at $PWD"
    if [ "$PWD" = "$HOME" ] ; then
      erecho ":: Home and PWD/CWD are the same"
      erecho ":: Failed to locate *$InSitename*.war in $PWD"
      erecho ":: Please use -w [warfile]"
      exit
    fi
    qecho ": Checking $HOME for war file matching *$InSitename*.war"
    War=`CheckForWarAt $HOME`
    if [ "$War" = "TooDamnMany" ] ; then exit; fi
    if [ "$War" = "--none--" ] ; then
      erecho ":: Failed to locate *$InSitename*.war in $PWD or $HOME"
      erecho ":: Please use -w [warfile]"
      exit
    fi
  fi
  qecho ":: Warfile found: $War"
else
  if [ -e $War ]; then
    qecho ": Warfile $War exists."
  else
    qecho ": Warfile $War doesn\'t exist."
    exit
  fi
fi

# -----------------------------------
# if $Context unset use warfile name
if [ "$Context" = "" ] ; then
  Context=`echo "$War" | awk -F\/ '{ print $NF }' | awk -F\. '{ print $1 }'`
  qecho ": Context not set; using: $Context"
fi

# -----------------------------------
# $Context root or _ convert to ROOT
if [ "$Context" = "root" -o "$Context" = "_" ] ; then
  qecho ": Converting $Context to ROOT"
  Context="ROOT"
fi

# -----------------------------------
# Check to make sure $Context exists
# assuming this isn't a new deploy

if [ "$NewContext" = "1" ] ; then
  qecho ": NewContext option set; skipping Context exists check"
else
  if [ -d $appBase/$Context ] ; then
    qecho ": Context $Context exists at $appBase/$Context"
  else
    erecho ": Context $Context doesn't exist"
    erecho ": Please use -c [context]"
    exit
  fi
fi

# -----------------------------------
# if $TimeLimit is unset, set to 60

if [ "$TimeLimit" = "" ] ; then
  TimeLimit="60"
  qecho ": TimeLimit defaulted to 60 seconds"
fi

# -----------------------------------
# if $KillLimit is unset, set to 60

if [ "$KillLimit" = "" ] ; then
  KillLimit="60"
  qecho ": KillLimit defaulted to 60 seconds"
fi

qecho "------------------------------"

qecho " Deleting old war and context"
sudo rm -rf $appBase/$Context{,.war}

qecho " Unzipping $War into $Context context"
sudo unzip -q -d $appBase/$Context $War

qecho " Copying $War next to $Context context"
sudo cp $War $appBase/$Context.war

qecho " Clearing cache (Precautionary, not 100% necessary)"
if [ "$Context" = "ROOT" ] ; then
  sudo rm -rf /var/cache/tomcat7/Catalina/$Sitename/_
else
  sudo rm -rf /var/cache/tomcat7/Catalina/$Sitename/$Context
fi

qecho "------------------------------"

# -----------------------------------
# if Touch conf is set, touch file...

if [ "$TouchConf" = "1" ] ; then
  qecho " Touching $TCConf/$Sitename/$Context.xml"
  sudo touch $TCConf/$Sitename/$Context.xml
fi
# -----------------------------------
# All that's left is to restart (or
# not) tomcat.

# -----------------------------------
# First, check to see if no restart is set.

if [ "$NoRestartTC" = "1" ] ; then
  qecho " Done"
  exit
fi

# -----------------------------------
# If we have set RestartTC, then ask

if [ "$RestartTC" != "1" ] ; then
  while true ; do
    echo -n "`date +%T` : Restart Tomcat5 [y/n]:"
    read CONFIRM
    case $CONFIRM in
      y|Y|YES|yes|Yes ) break ;;
      n|N|no|NO|No    ) qecho " Not Restarting Tomcat" ;
                        qecho " Done" ;
                        exit  ;;
    esac
  done
fi

# -----------------------------------
# restart tomcat!

qecho " Stopping tomcat..."
sudo /etc/init.d/tomcat7 stop

# -----------------------------------
# Verify that tomcat has stopped

# -----------------------------------
# nab the current time in case we need
# to starting killing - but for no
# longer than $KillLimit

TCInvokeEnd=`date +%s`

# -----------------------------------
# nab current list of Tomcat processes
# and how many
TCPIDs=`ps a | grep "org.apache.catalina.startup.Bootstrap start" | grep -v grep | awk '{print $1}'`
TCPIDNum=`echo $TCPIDs | awk '{print NF}'`

# -----------------------------------
# notify user if there's killing to do
if [ $TCPIDNum -gt 0 ] ; then
  qecho " /etc/init.d/tomcat7 stop failed to kill tomcat"
  qecho " There are $TCPIDNum processes matching:"
  qecho " matching \"org.apache.catalina.startup.Bootstrap start\:"
  qecho " Will now atempt to kill -9 [pid] for each matching process"
fi

# -----------------------------------
# loop until there's no more left or
# $KillLimit timelimit has been reached
while [ $TCPIDNum -gt 0 ] ; do
  if [ `date +%s` -gt $(( $TCInvokeEnd + $KillLimit )) ] ; then
    erecho " Tomcat is still running after expiration of kill time limit"
    erecho " Tomcat has NOT been restarted"
    exit
  fi

  for i in $TCPIDs ; do
    qecho " Killing PID $i"
    kill -9 $i
  done
  sleep 1

  TCPIDs=`ps a | grep "org.apache.catalina.startup.Bootstrap start" | grep -v grep | awk '{print $1}'`
  TCPIDNum=`echo $TCPIDs | awk '{print NF}'`
done

qecho " tomcat stopped."

# -----------------------------------
# nab the time between stopping and
# starting tomcat
TCLogSizeOld=`du -b $TCLog | awk '{ print $1 }'`

qecho " Starting tomcat..."
sudo /etc/init.d/tomcat7 start

# -----------------------------------
# nab the time after /etc/init.d/tomcat7 start is done
TimeStart=`date +%s`

# size of $TCLog nabbed between stop and start above...
# check for new size once a second
# if bigger, check new part for $TCLogStartStr
# if found, say so and exit, otherwise
# set old log size to the recently found one
#
# This is actually a pretty neat
# snippet of code.
# at it's core, it's essentially:
# 'tail until match found'

while sleep 1 ; do
  TCLogSizeNew=`du -b $TCLog | awk '{ print $1 }'`
  if [ $TCLogSizeNew -gt $TCLogSizeOld ] ; then
    TCStartup=`tail -c +$TCLogSizeOld $TCLog | grep "$TCLogStartupStr"`
    if [ "$TCStartup" != "" ] ; then
      if [ "$EchoedDots" = "1" -a "$NoPrompts" != "1" ] ; then echo ; fi
      qecho " Startup in $TCStartup ms"
      qecho " Done"
      exit
    else
      TCLogSizeOld="$TCLogSizeNew"
    fi
  fi
  TimeNow=`date +%s`
  TimeRun=$(( $TimeNow - $TimeStart ))

  if [ $TimeRun -ge $TimeLimit ] ; then
    if [ "$EchoedDots" = "1" ] ; then qecho ; fi
    qecho " TimeLimit expired waiting for $TCLog to indicate:"
    qecho ": \"$TCLogStartupStr\""
    qecho ": Verify tomcat startup"
    echo
    exit
  else
    if [ "$NoPrompts" != "1" ] ; then
      echo -n "."
      EchoedDots="1";
    fi
  fi
done

exit
