#!/usr/bin/env bash

cd "$(dirname "$0")"
source partytime.conf
CURRENTHOST=$(hostname -s)

show_usage() {
    echo "Usage: $0 [--add | --remove]"
    echo "  --add       Add host to Backburner Group"
    echo "  --remove    Remove host from Backburner Group"
}

# No options means we should display usage
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

# Save the option in a variable
ACTION=""

while [[ "$1" != "" ]]; do
    case $1 in
        --add)
            shift
            ACTION="add"
            ;;
        --remove)
            shift
            ACTION="remove"
            ;;
        *)
            echo "Invalid option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

ping_bbm () {
  while true; do
    # Ping the host with a single packet
    ping -c 1 $BBMANAGER

    # Check if the ping was successful
    if [ $? -eq 0 ]; then
        echo "Ping to $BBMANAGER was successful!"
        break
    else
        echo "Ping to $BBMANAGER failed. Retrying..."
        # Optional: wait for a specific duration before trying again
        sleep 1
    fi
done
}

wiretapping_bbm () {
  while true; do
    # Ping the host with a single packet
    /opt/Autodesk/wiretap/tools/current/wiretap_ping -h $BBMANAGER:Backburner

    # Check if the ping was successful
    if [ $? -eq 0 ]; then
        echo "Wiretap Ping to $BBMANAGER was successful!"
        break
    else
        echo "Wiretap Ping to $BBMANAGER failed. Retrying..."
        # Optional: wait for a specific duration before trying again
        sleep 1
    fi
done
}

#ping_bbm
#wiretapping_bbm

for BBGROUP in "${BBGROUPS[@]}"; do
  BBGROUPINFO=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info)
  if [[ $ACTION == "add" ]]; then
    ##This adds the current host to the server XML list
    BBGROUPINFO=$(echo $BBGROUPINFO | xmlstarlet ed --update "/info/servers" -x "concat(.,',${CURRENTHOST}')")   
  elif [[ $ACTION == "remove" ]]; then
    ##Fetch the current server list
    BBGROUPSERVERS=$(echo "$BBGROUPINFO" | xmlstarlet sel -t -v "/info/servers")
    ##Remove the current hostname from the list
    BBGROUPSERVERS=$(echo $BBGROUPSERVERS | sed "s/\b$CURRENTHOST\b//; s/,,/,/; s/^,//; s/,$//")
    ##Update modified server list in  XML
    BBGROUPINFO=$(echo "$BBGROUPINFO" | xmlstarlet ed --update "/info/servers" --value "$BBGROUPSERVERS")
  fi
  /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info -f /dev/stdin <<<"$BBGROUPINFO"
done
