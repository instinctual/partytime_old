#!/usr/bin/env bash
INSTALLDIR=/opt/instinctual/partytime

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit
fi

packagesInstalled=false

echo "Checking if XMLstarlet is installed..."

if [[ "$(rpm -qa | grep xmlstarlet)" != "" ]]
then
  packagesInstalled=true
else
  read -p "Partytime requires xmlstarlet. Would you like to install? y/n: " choice
  case "$choice" in
    y|Y ) echo "Testing for Internet connectivity.  Please wait.";
    ping -W2 -c1 google.com > /dev/null
    if [ $? -eq 0 ]
      then
        yum install -y epel-release
        yum -y install xmlstarlet
        packagesInstalled=true

      else
        echo "Please enable internet connectivity and run again."
        exit 0
    fi;;
    n|N ) exit 0;;
    * ) echo "invalid input, please enter y/n";
    exit 0;;
  esac
fi

if [ $packagesInstalled = true ]
then
  mkdir -p $INSTALLDIR
  install -v -m 555 partytimewrapper.sh $INSTALLDIR
  install -v -m 555 partytime.sh $INSTALLDIR



  if [ ! -f "$INSTALLDIR/partytime.conf" ]
    then
    install -v -m 644 partytime.conf.sample $INSTALLDIR/partytime.conf
  else
    echo "Existing config file found, no new config file created."
  fi
  install -v -m 555 partytime.desktop /etc/xdg/autostart/partytime.desktop
  install -v -m 444 partytime.service /etc/systemd/system/partytime.service
  systemctl enable partytime.service
fi
