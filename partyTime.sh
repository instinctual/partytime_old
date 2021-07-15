#!/usr/bin/env bash
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info


# echo "groupNames: $1";

runJoin=false
runRemove=false

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
  # echo "hi"

  # echo $runJoin
  updated="bbnode01"

  /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info > serverInfo.xml
  rawData=$(/Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info)

  serverGroupAttributes=$(perl -ne 'print and last if s/.*<servers>(.*)<\/servers>.*/\1/;' <<< "$rawData")

  updatedServerGroupAttributes=$serverGroupAttributes

  serverGrouparray=(${updatedServerGroupAttributes//,/ })
  # echo ${serverGrouparray[@]}
  # echo $serverGrouparray
  # echo ${serverGrouparray[@]}
  # echo $runJoin
  # updatedServerGroupAttributes+=","
  # updatedServerGroupAttributes+=$updated
  if [ $runJoin == true ]
  then
    finalGroupLine=""
    # echo ${serverGrouparray[@]}
    # echo ${serverGrouparray[@]}
    #
    # echo "${#serverGrouparray[@]}"

    for joinElement in ${serverGrouparray[@]}
    do
      # echo $joinElement
      finalGroupLine+=$joinElement
      finalGroupLine+=","
      # echo $finalGroupLine
    done
    finalGroupLine+=$updated

    # # echo "here"
    # updatedArray=()
    # finalGroupLine=""
    # if [ ${#serverGrouparray[@]} == 0 ]
    # then
    #   $updatedArray+="{$updated}"
    #   finalGroupLine=$updatedArray
    # else
    #   n=0
    #   for element in ${serverGrouparray[@]}
    #   do
    #     if (( n < ${#updatedArray[@]} ))
    #     then
    #       finalGroupLine+="${element}"
    #       finalGroupline+=","
    #       # echo $finalGroupLine
    #     else
    #       finalGroupline+="${update}"
    #     fi
    #     ((++n))
    #
    #   done
    # fi
    # # echo $runJoin
    # echo $finalGroupline
    # updatedServerGroupAttributes+=","
    # updatedServerGroupAttributes+=$updated
  # finalGroupLine="bbmdev"

  fi

  if [ $runRemove == true ]
  then
    updatedArray=()
    finalGroupLine=""
    # echo "remove"
    # echo ${serverGrouparray[@]}
    i=0
    # echo "${#serverGrouparray[@]}"
    for element in ${serverGrouparray[@]}
    do
      if [ $element != $updated ]
      then
        updatedArray[$i]=$element
      fi
      ((++i))
    done
    # echo ${updatedArray[@]}

    j=1
    for groupNameIterator in ${updatedArray[@]}
    do
      finalGroupLine+=$groupNameIterator
      if (( j < ${#updatedArray[@]} ))
      then
        finalGroupLine+=","
      fi
      # echo $j
      ((++j))
    done
    # echo $finalGroupLine

    # delete=bbmdev
    # echo ${serverGrouparray[@]/$delete}
    # newRemovedArray=( "${serverGrouparray[@]/$delete}" )
    # echo ${newRemovedArray[@]}
    # echo ${#newRemovedArray[@]}

  fi
  # updatedServerGroupAttributes+=","
  updatedServerGroupAttributes=$finalGroupLine
  xml ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes serverInfo.xml

  # xml ed --inplace -a "/info/servers" --type attr -n servers -v $updated serverInfo.xml

  # echo "hi"+$individualGroup

  /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_set_metadata -h 192.168.101.10:Backburner -n /servergroups/$individualGroup -s info -f serverInfo.xml
done

# echo $S

# rawData=$(/Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info)

# updated="bbmdev"
#
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_get_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info > serverInfo.xml
#
# serverGroupAttributes=$(perl -ne 'print and last if s/.*<servers>(.*)<\/servers>.*/\1/;' <<< "$rawData")
#
# updatedServerGroupAttributes=$serverGroupAttributes
# updatedServerGroupAttributes+=","
# updatedServerGroupAttributes+=$updated
#
# xml ed --inplace -u "/info/servers" -v $updatedServerGroupAttributes serverInfo.xml
#
# # xml ed --inplace -a "/info/servers" --type attr -n servers -v $updated serverInfo.xml
#
#
# /Volumes/SCRATCH/wiretapSDK_2022_MACOSX/tools/MACOSX/x86_64/10_14_6/wiretap_set_metadata -h 192.168.101.10:Backburner -n /servergroups/group01 -s info -f serverInfo.xml


# echo $rawData
# echo $HOSTNAME
# xmlstarlet sel -t -v "count(//servers)" $rawData
#
# newData=$(xml ed -u "/info/servers" -v 0 $rawData)
# echo $newData
# #
# serverGroup=$(grep -oPm1 "(?<=<servers>)[^<]+" <<< "$rawData")
# serverGroup2=$(perl -ne 'print and last if s/.*<servers>(.*)<\/servers>.*/\1/;' <<< "$rawData")
# # echo "$serverGroup"
# # echo $rawData
# echo $serverGroup2
# read -a attributeArray <<< $rawData

# xmlcatalog --create
#
# xmlcatalog --add PUBLIC

# echo "My array: ${attributeArray[2]}"
#
# for i in ${attributeArray[@]}
# do
#   if [[ $i =~ "server" ]]
#   then
#     echo $i | grep -o '<servers>.*</servers>' $i | sed 's/\(<servers>\|<\/servers>\)//g'
#     echo "Hi+$i"
#     echo $hello
#   fi
#
# done
