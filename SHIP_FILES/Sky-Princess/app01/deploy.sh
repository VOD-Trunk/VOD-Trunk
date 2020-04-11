









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






qecho()
{
if [ "$NoPrompts" != "1" ] ; then eecho "$*" ; fi
}





eecho()
{
echo `date +%T` :"$*"
}




erecho()
{
echo "`date +%T` :$*" > /dev/stderr
}






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







InSitename="$Sitename"






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





qecho " Checking options ..."




if [ "$RestartTC" = "1" -a "$NoRestartTC" = "1" ] ; then
erecho ": Options: -r (Restart Tomcat) and"
erecho ":          -m (Do Not Restart Tomcat)"
erecho ": Cannot both be used"
exit
fi




if [ "$Sitename" = "" ] ; then
erecho "-v [sitename] required"
erecho
usage
exit
fi




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



if [ "$Context" = "" ] ; then
Context=`echo "$War" | awk -F\/ '{ print $NF }' | awk -F\. '{ print $1 }'`
qecho ": Context not set; using: $Context"
fi



if [ "$Context" = "root" -o "$Context" = "_" ] ; then
qecho ": Converting $Context to ROOT"
Context="ROOT"
fi





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




if [ "$TimeLimit" = "" ] ; then
TimeLimit="60"
qecho ": TimeLimit defaulted to 60 seconds"
fi




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




if [ "$TouchConf" = "1" ] ; then
qecho " Touching $TCConf/$Sitename/$Context.xml"
sudo touch $TCConf/$Sitename/$Context.xml
fi







if [ "$NoRestartTC" = "1" ] ; then
qecho " Done"
exit
fi




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




qecho " Stopping tomcat..."
sudo /etc/init.d/tomcat7 stop









TCInvokeEnd=`date +%s`




TCPIDs=`ps a | grep "org.apache.catalina.startup.Bootstrap start" | grep -v grep | awk '{print $1}'`
TCPIDNum=`echo $TCPIDs | awk '{print NF}'`



if [ $TCPIDNum -gt 0 ] ; then
qecho " /etc/init.d/tomcat7 stop failed to kill tomcat"
qecho " There are $TCPIDNum processes matching:"
qecho " matching \"org.apache.catalina.startup.Bootstrap start\:"
qecho " Will now atempt to kill -9 [pid] for each matching process"
fi




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




TCLogSizeOld=`du -b $TCLog | awk '{ print $1 }'`

qecho " Starting tomcat..."
sudo /etc/init.d/tomcat7 start



TimeStart=`date +%s`












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
