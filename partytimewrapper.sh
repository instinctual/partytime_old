#!/usr/bin/env bash

## This script launches at login, removes the host from specificed BB Groups.  
## It then waits running in the background for logout, and then adds the host to specified BB Groups.

partytime_add() {
  nohup sudo systemctl start partytime.service >/dev/null 2>&1 &
}

sudo systemctl stop partytime.service >/dev/null 2>&1 &

trap partytime_add INT TERM EXIT
sleep infinity