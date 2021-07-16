#!/usr/bin/env bash

DISPLAY=`w -h | awk '$2 ~ /:[0-9.]*/{print $2}'`

function powersave {
	nohup tuned-adm profile balanced >/dev/null 2>&1 &
	nohup /usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0" >/dev/null 2>&1 &
}

tuned-adm profile autodesk
/usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1"

trap powersave INT TERM EXIT
sleep infinity
