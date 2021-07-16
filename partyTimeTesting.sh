#!/usr/bin/env bash
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info
source partyTime.conf
echo $bbmmanager
# echo "groupNames: $1";

function partyTimeJoin {
	nohup tuned-adm profile balanced >/dev/null 2>&1 &
	nohup /usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" >/dev/null 2>&1 &
}

function partyTimeRemove {
	nohup tuned-adm profile balanced >/dev/null 2>&1 &
	nohup /usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" >/dev/null 2>&1 &
}

tuned-adm profile autodesk
/usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1"

trap powersave INT TERM EXIT
sleep infinity


runJoin=false
runRemove=false
machineExists=false
useCommandLine=false

while [ $# -gt 0 ] ; do
  case $1 in
    -g | --groups)
    S="$2"
    groupArray=(${2//,/ }); useCommandLine=true;;
    -j | --join) J="$1";runJoin=true;;
    -r | --remove) R="$2";runRemove=true;;
    # -b | --barg) B="$2" ;;

  esac
  shift
done
echo $useCommandLine
echo $S
if [ $useCommandLine == false ]
then
  echo "hi"
  groupArray=$bbgroups
fi
echo $groupArray
for individualGroup in "${groupArray[@]}"
do
  updated=$HOSTNAME
  #should be Hostname
  echo $S
  /opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info > /tmp/partyTime.xml

  # /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$individualGroup -s info > serverInfo.xml
  rawData=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info)

  serverGroupAttributes=$(perl -ne 'print and last if s/.*<servers>(.*)<\/servers>.*/\1/;' <<< "$rawData")

  updatedServerGroupAttributes=$serverGroupAttributes

  serverGrouparray=(${updatedServerGroupAttributes//,/ })

  for check in ${serverGrouparray[@]}
  do
    if [ $check == $updated ]
    then
      machineExists=true
    fi
  done

  if [ $runJoin == true ]
  then
    finalGroupLine=""
    q=0
    for joinElement in ${serverGrouparray[@]}
    do
      finalGroupLine+=$joinElement
      if (( q < ${#serverGrouparray[@]}-1 ))
      then
        finalGroupLine+=","
      fi
      ((++q))
    done
    if [ $machineExists == false ]
    then
      if (( ${#serverGrouparray[@]} != 0))
      then
        finalGroupLine+=","
      fi
      finalGroupLine+=$updated
    fi
  fi

  if [ $runRemove == true ]
  then
    updatedArray=()
    finalGroupLine=""
    i=0
    for element in ${serverGrouparray[@]}
    do
      if [ $element != $updated ]
      then
        updatedArray[$i]=$element
      fi
      ((++i))
    done
    j=1
    for groupNameIterator in ${updatedArray[@]}
    do
      finalGroupLine+=$groupNameIterator
      if (( j < ${#updatedArray[@]} ))
      then
        finalGroupLine+=","
      fi
      ((++j))
    done

  fi
  updatedServerGroupAttributes=$finalGroupLine
  fixedData=${rawData//[$'\t\r\n']}
  xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes /tmp/partyTime.xml
  /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f /tmp/partyTime.xml
done
