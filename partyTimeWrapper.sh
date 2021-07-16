#!/usr/bin/env bash
function partyTimeRemove {
	# nohup tuned-adm profile balanced >/dev/null 2>&1 &
	# nohup /usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" >/dev/null 2>&1 &

  /opt/instinctual/partyTime/partyTime.sh --remove &

}


/opt/instinctual/partyTime/partyTime.sh --join &

trap partyTimeRemove INT TERM EXIT
sleep infinity
