#!/usr/bin/env bash
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info

#sleep 30

cd "$(dirname "$0")"
source partytime.conf
# printf "%s" "waiting for ServerXY ..."
# while ! ping -c 5 -w 30 $bbmmanager #&> /dev/null
# do
#     printf "%c" "."
# done



# echo $bbmmanager
# ping -c 2 $bbmmanager



while ! ping -c 1 -n -w 1 $bbmmanager
do
    sleep 1
    printf "%c" "."
done
printf "\n%s\n"  "Ping1 complete"


while ! /opt/Autodesk/wiretap/tools/current/wiretap_ping -h $bbmmanager:Backburner
# sleep 1
do
    sleep 1
    printf "%c" "."
done
printf "\n%s\n"  "Wiretap Ping complete"




runJoin=false
runRemove=false
machineExists=false
useCommandLine=false
deleteTag=false


sleep 1

# this loop collects information from command line
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
echo $J
echo runRemove? $runRemove
#if no input received in the command line, uses data from setup file
if [ $useCommandLine == false ]
then
  groupArray=(${bbgroups//,/ })

fi
# loops through groups in list
for individualGroup in "${groupArray[@]}"
do
  moveOn=false

  updated=$HOSTNAME
  # /opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info > /tmp/partyTime.xml

  deleteTag=false
  onlyOne=false

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
    else
      #resets for next round
      machineExists=false
    fi

  fi

  if [ $runRemove == true ]
  then
    if [[ ${serverGrouparray[@]} == "" ]]
    then
      moveOn=true
    fi

    if [ $moveOn == false ]
    then
      if (( ${#serverGrouparray[@]} == 1 )) && [ ${serverGrouparray[0]} == $updated ]
      then
        onlyOne=true
      else
        onlyOne=false
      fi

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
          deleteTag=true
        fi
      fi

  fi
  updatedServerGroupAttributes=$finalGroupLine
  fixedData=${rawData//[$'\t\r\n']}


  if [ $moveOn == true ]
  then

     if [ $deleteTag == false ]
     then
       quit=true
       #this loop is only here to catch it before it goes to next part
       # xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes /tmp/partyTime.xml
     fi
  elif [ $deleteTag == true ]
  then
    # xmlstarlet ed --inplace -d "/info/servers" /tmp/partyTime.xml
    # xmlstarlet ed --inplace -s /info -t elem -n servers -v "" /tmp/partyTime.xml
    newData=$(xmlstarlet fo -t - <<<"$rawData")

    temp1Delete=$(xmlstarlet ed --inplace -d "/info/servers" <<< $newData)
    newData=$(xmlstarlet ed --inplace -s /info -t elem -n servers -v "" <<< $temp1Delete)
    # xmlstarlet ed --inplace -u "/info/" -v "servers" /tmp/partyTime.xml

  else
    newData=$(xmlstarlet fo -t - <<<"$rawData")
    # xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes /tmp/partyTime.xml
    # echo $updatedServerGroupAttributes
    finalXML=$(xmlstarlet ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes <<< $newData)
    newData=$(xmlstarlet fo -t - <<<"$finalXML")
    # echo "new:" $newData

  fi

  # /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f /tmp/partyTime.xml
  # /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f "$(cat newData)"
  # mkfifo named.pipe
  # printf '%s\n' "$newData" >named.pipe & writer=$!
  #
  # /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f named.pipe
  # rm named.pipe
  # wait "$writer"
  /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $bbmmanager:Backburner -n /servergroups/$individualGroup -s info -f /dev/stdin <<<"$newData"


done
