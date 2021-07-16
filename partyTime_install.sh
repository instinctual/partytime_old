#!/usr/bin/env bash
ENGINEERING=/vol/engineering
HOSTNAME=`hostname -s`
source /etc/os-release
source $ENGINEERING/tools/installers/config/machines/$HOSTNAME.conf

###CentOS 7###

if [[ $VERSION_ID = "7" ]]
  then

echo "Installing Powersave ON"

cat <<EOF > /etc/kde/shutdown/powersave_on.sh
#!/bin/sh
sudo cpupower frequency-set --governor conservative
nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0"
EOF
chmod +x /etc/kde/shutdown/powersave_on.sh

echo "Installing Powersave OFF"
cat <<EOF > /etc/kde/env/powersave_off.sh
#!/bin/sh
sudo cpupower frequency-set --governor performance
nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=1"
EOF

  chmod +x /etc/kde/env/powersave_off.sh

  echo "Turning off Nvidia Powersave in Xorg"
  sed -i 's/Option      "RegistryDwords"/# &/' /etc/X11/xorg.conf


  echo "Install Powersave Service"

  cat <<EOF > /etc/systemd/system/powersave.service
[Unit]
Description=Nvidia PowerSave
After=graphical.target

[Service]
Environment="DISPLAY=:0.0"
ExecStart=/usr/bin/nvidia-settings -a "[gpu:0]/GpuPowerMizerMode=0"

[Install]
WantedBy=graphical.target
EOF

  systemctl enable --now powersave.service


##CPU Govenor

  echo "Changing CPU governor."

  if [[ $MACHINETYPE == 'workstation' ]]
    then
      echo "WORKSTATION"
      sed -i 's/\governor=performance/\governor=conservative/' /usr/lib/tuned/autodesk/tuned.conf
  elif [[ $MACHINETYPE == 'render' ]]
    then
      sed -i 's/\governor=performance/\governor=conservative/' /usr/lib/tuned/autodesk/tuned.conf
      sed -i 's/\governor=conservative/\governor=ondemand/' /usr/lib/tuned/autodesk/tuned.conf
  fi
fi

###CentOS 8###

if [[ $VERSION_ID = "8" ]]
  then
    echo "Turning off Nvidia Powersave in Xorg"
    sed -i 's/Option      "RegistryDwords"/# &/' /etc/X11/xorg.conf

        ##Create XDG Autostart PowerSave
        mkdir -p /opt/instinctual

        /usr/bin/cp -v $ENGINEERING/tools/installers/system/powersave/powersave.sh /opt/instinctual/
        chmod a+rx /opt/instinctual/powersave.sh
        /usr/bin/cp -v $ENGINEERING/tools/installers/system/powersave/powersave.desktop /etc/xdg/autostart/
        chmod a+rx /etc/xdg/autostart/powersave.desktop

        ##Install PowerSave systemd service.
        /usr/bin/cp -fv $ENGINEERING/tools/installers/system/powersave/powersave.service /etc/systemd/system/
        chmod a-x /etc/systemd/system/powersave.service
        systemctl enable powersave.service

  fi

echo "Install INS powersave measures on `date`" >> /opt/instinctual/changelog
