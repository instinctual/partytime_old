#!/usr/bin/env bash
INSTALLDIR=/opt/instinctual/partytime
ENGINEERING=/vol/engineering
HOSTNAME=`hostname -s`
source /etc/os-release

cd "$(dirname "$0")" || exit
CURRENTDIR=`pwd`

for CONFFILE in $ENGINEERING/tools/installers/global/*.conf
do
  source "$CONFFILE"
done

check_internet
check_machineconffile

cd $CURRENTDIR

if [[ $MACHINETYPE == 'workstation' ]]
  then
  if [ "$EUID" -ne 0 ]
    then echo "This installer must be run as root."
    exit
  fi

  dnf install -y epel-release
  dnf -y install xmlstarlet
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
    echo "PartyTime has been installed."
fi
