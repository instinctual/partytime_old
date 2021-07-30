#!/usr/bin/env bash
function partyTimeJoin {
  nohup /opt/instinctual/partytime/partytime.sh --join >/dev/null 2>&1 &
}

/opt/instinctual/partytime/partytime.sh --remove &

trap partyTimeJoin INT TERM EXIT
sleep infinity
