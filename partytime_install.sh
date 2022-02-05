#!/usr/bin/env bash
INSTALLDIR=/opt/instinctual/partytime
ENGINEERING=/vol/engineering
HOSTNAME=`hostname -s`
source /etc/os-release
source $ENGINEERING/tools/installers/config/machines/$HOSTNAME.conf


if [[ $MACHINETYPE == 'workstation' ]]
  then

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]
  then echo "This installer must be run as root."
  exit
fi

packagesInstalled=false

echo "Checking if XMLstarlet is installed..."

if [[ "$(rpm -qa | grep xmlstarlet)" != "" ]]
then
  echo "XMLstarlet is already installed."
  packagesInstalled=true
else
  read -p "Partytime requires xmlstarlet. Would you like to install? y/n: " choice
  case "$choice" in
    y|Y ) echo "Testing for Internet connectivity.  Please wait.";
    ping -W2 -c1 google.com > /dev/null
    if [ $? -eq 0 ]
      then
        dnf install -y epel-release
        dnf -y install xmlstarlet
        packagesInstalled=true

      else
        echo "Please enable internet connectivity and run again."
        exit 0
    fi;;
    n|N ) exit 0;;
    * ) echo "Invalid input, please enter y/n.";
    exit 0;;
  esac
fi

if [ $packagesInstalled = true ]
then
  mkdir -p $INSTALLDIR
  install -m 555 partytimewrapper.sh $INSTALLDIR
  install -m 555 partytime.sh $INSTALLDIR



  if [ ! -f "$INSTALLDIR/partytime.conf" ]
    then
    install -m 644 partytime.conf.sample $INSTALLDIR/partytime.conf
    echo "**********************************************************************************************"
    echo "You MUST edit partytime.conf with the proper Backburner Manager and Groups info for your site."
    echo "**********************************************************************************************"
  else
    echo "Existing config file found, not replacing."
  fi
  install -m 555 partytime.desktop /etc/xdg/autostart/partytime.desktop
  install -m 444 partytime.service /etc/systemd/system/partytime.service
  systemctl enable partytime.service
fi
echo "PartyTime has been installed."

fi
