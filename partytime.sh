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

##We have to do these pings, as Wiretap needs a kick to actually connect to the Manager
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
    /opt/Autodesk/wiretap/tools/current/wiretap_ping -t 100 -h $BBMANAGER:Backburner

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
wiretapping_bbm

for BBGROUP in "${BBGROUPS[@]}"; do
  BBGROUPINFO=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info)
  if [[ $ACTION == "add" ]]; then
    BBGROUPINFO=$(echo $BBGROUPINFO | xmlstarlet ed --update "/info/servers" -x "concat(.,',${CURRENTHOST}')")   ##This adds the current host to the server XML list
  elif [[ $ACTION == "remove" ]]; then
    # Stop the ADSK Backburner service to kill and currently running jobs.  We don't want a Burn job going on in the background while we use Flame.
    sudo systemctl stop adsk_backburner
    # Isolate the current server list
    BBGROUPSERVERS=$(echo "$BBGROUPINFO" | xmlstarlet sel -t -v "/info/servers")
    # Remove the current hostname from the list
    BBGROUPSERVERS=$(echo $BBGROUPSERVERS | sed "s/\b$CURRENTHOST\b//; s/,,/,/; s/^,//; s/,$//")
    # Update modified server list into the XML
    BBGROUPINFO=$(echo "$BBGROUPINFO" | xmlstarlet ed --update "/info/servers" --value "$BBGROUPSERVERS")
    # Start the ADSK Backburner Service for Flame needs it.
    sudo systemctl start adsk_backburner
  fi
  /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info -f /dev/stdin <<<"$BBGROUPINFO"
done