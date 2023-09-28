#!/usr/bin/env bash

INSTALLDIR=/opt/instinctual/partytime

cd "$(dirname "$0")" || exit
CURRENTDIR=`pwd`
cd $CURRENTDIR

# If the script is not running as root, it won't have permissions to install packages.
# So, check if the user has root privileges
if [[ $UID -ne 0 ]]; then
    echo "You must be root to install packages. Try running with sudo or as root."
    exit 1
fi

check_internet() {
  echo "Testing for Internet connectivity to google.com.  Please wait."
  ping -W2 -c1 google.com > /dev/null
  if [ $? -eq 0 ]
    then
      echo "Internet is good.  Moving On."
      echo
    else
      echo "Installer needs Internet connectivity. Open the firewall and try again."
      exit 0
  fi
}

# Check if xmlstarlet is installed
if ! rpm -q xmlstarlet &>/dev/null; then
    echo
    echo "xmlstarlet is NOT installed."
    read -p "Do you want to install xmlstarlet? This will also install epel-release. (y/n) " choice

    case $choice in
        y|Y)
            check_internet
            # Attempt to install xmlstarlet
            dnf install -y epel-release
            dnf update -y epel-release
            dnf install -y xmlstarlet
            ;;
        n|N)
            echo "Exiting without installing xmlstarlet."
            exit 1
            ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

  mkdir -p $INSTALLDIR
  install -m 555 partytimewrapper.sh $INSTALLDIR
  install -m 555 partytime.sh $INSTALLDIR
  install -m 440 partytime.rules /etc/sudoers.d/partytime

#Check to see if there is an existing configuration file.  Always copy a .sample for future reference.
if [ ! -f "$INSTALLDIR/partytime.conf" ]
  then
    install -m 664 partytime.conf.sample $INSTALLDIR/partytime.conf
    echo "**********************************************************************************************"
    echo "You MUST edit partytime.conf with the proper Backburner Manager and Groups info for your site."
    echo "**********************************************************************************************"
else
  install -m 664 partytime.conf.sample $INSTALLDIR/partytime.conf.sample
  echo "Existing config file found, not replacing. Adding .sample file."
fi

install -m 444 partytime.desktop /etc/xdg/autostart/partytime.desktop
install -m 444 partytime.service /etc/systemd/system/partytime.service
systemctl daemon-reload
systemctl enable --now partytime.service
echo "PartyTime has been installed."