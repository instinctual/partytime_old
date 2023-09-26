#!/usr/bin/env bash

PARTYTIMEBIN=/opt/instinctual/partytime/partytime.sh

partytime_add() {
  nohup $PARTYTIMEBIN --add >/dev/null 2>&1 &
}

$PARTYTIMEBIN --remove &

trap partytime_add INT TERM EXIT
sleep infinity
