#!/usr/bin/env bash
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info


# echo "groupNames: $1";

runJoin=false
runRemove=false
machineExists=false

while [ $# -gt 0 ] ; do
  case $1 in
    -g | --groups)
    S="$2"
    groupArray=(${2//,/ });;
    -j | --join) J="$1";runJoin=true;;
    -r | --remove) R="$2";runRemove=true;;
    # -b | --barg) B="$2" ;;

  esac
  shift
done

for individualGroup in "${groupArray[@]}"
do
  updated="bbnode01"
  #should be Hostname

  /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info > serverInfo.xml
  rawData=$(/Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info)

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
      finalGroupLine+=","
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
  xml ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes serverInfo.xml
  /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_set_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info -f serverInfo.xml
done
