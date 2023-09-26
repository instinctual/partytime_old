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

# We have to do these pings, as Wiretap needs a kick sometimes to connect to the Manager
while true; do
    # Ping the host with a single packet
    /opt/Autodesk/wiretap/tools/current/wiretap_ping -t 100 -h $BBMANAGER:Backburner
    
    # Check if the ping was successful
    if [ $? -eq 0 ]; then
        #echo "Wiretap Ping to $BBMANAGER was successful!"
        break
    else
        #echo "Wiretap Ping to $BBMANAGER failed. Retrying..."
        sleep 1
    fi
done

# If we are removing the host, stop the ADSK Backburner service to kill any currently running jobs.
# We don't want a Burn job going on in the background while we use Flame.
# Add a 2 seconds sleep to make sure the `stop` finishes before we move on.
# if [[ $ACTION == "remove" ]]; then
#     sudo systemctl stop adsk_backburner ; sleep 2
# fi

#Loop thru specified groups and add or remove the host.
for BBGROUP in "${BBGROUPS[@]}"; do
    BBGROUPINFO=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info)
    if [[ $ACTION == "add" ]]; then
        BBGROUPSERVERS=$(echo "$BBGROUPINFO" | xmlstarlet sel -t -v "/info/servers")
        # Check if the CURRENTHOST exists in that list
        if ! echo $BBGROUPSERVERS | grep -q "\<${CURRENTHOST}\>"; then
            # If not, add the current host to the server XML list
            BBGROUPINFO=$(echo $BBGROUPINFO | xmlstarlet ed --update "/info/servers" -x "concat(.,',${CURRENTHOST}')")
        fi
    elif [[ $ACTION == "remove" ]]; then
        # Isolate the current server list
        BBGROUPSERVERS=$(echo "$BBGROUPINFO" | xmlstarlet sel -t -v "/info/servers")
        # Remove the current hostname from the list
        BBGROUPSERVERS=$(echo $BBGROUPSERVERS | sed "s/\b$CURRENTHOST\b//; s/,,/,/; s/^,//; s/,$//")
        # Update modified server list into the XML
        BBGROUPINFO=$(echo "$BBGROUPINFO" | xmlstarlet ed --update "/info/servers" --value "$BBGROUPSERVERS")
    fi
    #Sumbit the modified XML list to Backburner Manager
    sleep 2
    /opt/Autodesk/wiretap/tools/current/wiretap_set_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info -f /dev/stdin <<<"$BBGROUPINFO"
    echo "Submitted:"
    echo "$BBGROUPINFO"
    BBGROUPINFO=$(/opt/Autodesk/wiretap/tools/current/wiretap_get_metadata -h $BBMANAGER:Backburner -n /servergroups/$BBGROUP -s info)
    sleep 2
done

# If we are removing the host, start the ADSK Backburner Service for Flame needs it.
# Add a 2 seconds sleep to make sure the the XML submission finishes before we move on.
# if [[ $ACTION == "remove" ]]; then
#     sleep 2 ; sudo systemctl start adsk_backburner
# fi
