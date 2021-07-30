#!/usr/bin/env bash
INSTALLDIR=/opt/instinctual/partytime/

cd "$(dirname "$0")"

if [ "$EUID" -ne 0 ]
  then echo "Please run as root."
  exit
fi

##We should really check if these are installed, if not prompt.  This force install is not friendly.
yum install -y epel-release
yum -y install xmlstarlet

mkdir -p $INSTALLDIR
install -v -m 555 partytimewrapper.sh $INSTALLDIR
install -v -m 555 partytime.sh $INSTALLDIR
install -v -m 644 partytime.conf $INSTALLDIR
install -v -m 555 partytime.desktop /etc/xdg/autostart/partytime.desktop
install -v -m 444 partytime.service /etc/systemd/system/partytime.service

systemctl enable partytime.service
