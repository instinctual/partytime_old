#!/usr/bin/env bash

## This script launches at login, removes the host from specificed BB Groups.  
## It then waits running in the background for logout, and then adds the host to specified BB Groups.

PARTYTIMEBIN=/opt/instinctual/partytime/partytime.sh

partytime_add() {
  nohup "$PARTYTIMEBIN" --add >/dev/null 2>&1 &
}

"$PARTYTIMEBIN" --remove &

trap partytime_add INT TERM EXIT
sleep infinity
