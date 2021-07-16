#!/usr/bin/env bash
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info
source partyTime.conf
echo $bbmmanager
# echo "groupNames: $1";

runJoin=false
runRemove=false
machineExists=false
useCommandLine=false
deleteTag=false

while [ $# -gt 0 ] ; do
  case $1 in
    -g | --groups)
    S="$2"
    groupArray=(${2//,/ });useCommandLine=true;;
    -j | --join) J="$1";runJoin=true;;
    -r | --remove) R="$2";runRemove=true;;
    # -b | --barg) B="$2" ;;

  esac
  shift
done
# echo $useCommandLine
# echo "check"
# echo $groupArray[@]
if [ $useCommandLine == false ]
then
  # echo "hi"
  groupArray=(${bbgroups//,/ })
  # echo "check"
  # echo $groupArray

fi
echo $groupArray
for individualGroup in "${groupArray[@]}"
do
  updated=$HOSTNAME
  #should be Hostname
  echo "On: " + $individualGroup
  /opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info > /tmp/partyTime.xml
  # echo "ryan2"
  echo $bbmmanager
  echo $individualGroup
  deleteTag=false
  onlyOne=false
  echo $deleteTag
  moveOn=false


  # /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$individualGroup -s info > serverInfo.xml
  rawData=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info)
  echo "Raw Data" $rawData
  serverGroupAttributes=$(perl -ne 'print and last if s/.*<servers>(.*)<\/servers>.*/\1/;' <<< "$rawData")

  updatedServerGroupAttributes=$serverGroupAttributes

  serverGrouparray=(${updatedServerGroupAttributes//,/ })
  echo "array" ${serverGrouparray[@]}

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
    if [[ ${serverGrouparray[@]} == "" ]]
    then
      moveOn=true
    fi

    if (( ${#serverGrouparray[@]} == 1 )) && [ ${serverGrouparray[0]} == $updated ]
    then
      echo ${serverGrouparray[0]}
      echo "attr" $updated
      onlyOne=true
    else
      onlyOne=false
    fi



    echo "YOU ARE HERE"

    updatedArray=()
    finalGroupLine=""
    i=0
    for element in ${serverGrouparray[@]}
    do
      echo "element" $element
      if [ $element != $updated ]
      then
        updatedArray[$i]=$element
      fi
      ((++i))
    done
    j=1
    echo ${updatedArray[@]}


      echo "run?" $onlyOne
      if [ $onlyOne == false ]
      then
      for groupNameIterator in ${updatedArray[@]}
      do
        finalGroupLine+=$groupNameIterator
        if (( j < ${#updatedArray[@]} ))
        then
          finalGroupLine+=","
        fi
        ((++j))
      done
      else
        echo "YOU WERE MEANT TO DESTROY THE SITH NOT JOIN THEM"
        deleteTag=true
      fi

  fi
  updatedServerGroupAttributes=$finalGroupLine
  fixedData=${rawData//[$'\t\r\n']}
  echo "Attributes" $serverGroupAttributes

  if [[ $serverGroupAttributes == "" ]]
  then
    echo "nothing to see here!"
    moveOn=true
  fi

  if [ $moveOn == true ]
  then
     echo "moveON"
     echo "onlyOne?" $onlyOne
     echo $deleteTag
     if [ $deleteTag == false ]
     then
       xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes /tmp/partyTime.xml
     fi
  elif [ $deleteTag == true ]
  then
    xmlstarlet ed --inplace -d "/info/servers" /tmp/partyTime.xml
    xmlstarlet ed --inplace -s /info -t elem -n servers -v "" /tmp/partyTime.xml
    # xmlstarlet ed --inplace -u "/info/" -v "servers" /tmp/partyTime.xml

  else
    xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes /tmp/partyTime.xml
  fi
  echo "Hi"
  /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f /tmp/partyTime.xml
  echo "complete"
done
