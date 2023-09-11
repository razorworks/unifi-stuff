#!/bin/vbash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# define some logger for SYSLOG messages
LTN="logger -t wg-installer"
LTI="logger -p info -t wg-installer"
LTW="logger -p warn -t wg-installer"
LTE="logger -p error -t wg-installer"

# set some defaults
#WR="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
MODEL=THISISMYMODEL
AUTOSTART_PATH=/config/scripts/post-config.d
EXITCODE=42

# identify file path
CANON=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)/$(basename -- "$0")")

# get file permissions
OCTAL_ACCESS_RIGHTS=$(stat -c %a $CANON)

$LTI Script started.

# check for correct path
if [[ $(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)") != $AUTOSTART_PATH ]]; then
  echo
  echo " WRONG FILE LOCATION for auto-run!"
  echo
  echo " Move file to $AUTOSTART_PATH/ to run it after every reboot automatically."
  echo " You can use the following command to reach that goal:"
  echo
  echo " mv $CANON $AUTOSTART_PATH/"
  echo
  exit 42
fi

# check for correct file permissions
if [[ $OCTAL_ACCESS_RIGHTS != "755" ]]; then
  echo
  echo " WRONG FILE PERMISSIONS to execute!"
  echo
  echo " Set right permissions with following command:"
  echo
  echo " chmod +x $CANON"
  echo
  exit 42
fi

# check for supported model
if [[ $MODEL == "THISISMYMODEL" ]]; then
  echo
  echo " MODEL not set."
  echo
  echo " Script usage:"
  echo
  echo " Please run the following command to identify your hardware (USG-3 / USG-Pro-4):"
  echo
  echo "   info | grep -i \"model\" | cut -d : -f 2,3 | awk '{ gsub(/ /,\"\"); print }'"
  echo
  echo
  echo " Expected results:"
  echo
  echo "  UniFi-Gateway-3"
  echo "  UniFi-Gateway-4"
  echo
  echo " Please run one of the following commands to get the lastest WireGuard installer"
  echo "  from official github repository https://github.com/WireGuard/wireguard-vyatta-ubnt"
  echo "  for automatic installation - if necessary:"
  echo
  echo "  On a UniFi-Gateway-3: sed -i 's/THISISMYMODEL/UniFi-Gateway-3/g' /config/scripts/post-config.d/install-wireguard.sh"
  echo
  echo "  On a UniFi-Gateway-4: sed -i 's/THISISMYMODEL/UniFi-Gateway-4/g' /config/scripts/post-config.d/install-wireguard.sh"
  echo
  exit 42
fi

# set hardware based on model
if [[ $MODEL == "UniFi-Gateway-4" ]]; then
  HARDWARE=ugw4
else
  if [[ $MODEL == "UniFi-Gateway-3" ]]; then
    HARDWARE=ugw3
  else
    echo
    echo "   Hardware not supported."
    echo
    echo "   Please run following command to remove file:"
    echo
    echo "   rm $CANON"
    echo
    exit 42
  fi
fi
echo "Model: $MODEL"
echo "Hardware: $HARDWARE"

# generate download-URL
URL=$(curl -sl https://api.github.com/repos/WireGuard/wireguard-vyatta-ubnt/releases/latest \
| grep "browser_download_url.*$HARDWARE.*deb" \
| cut -d : -f 2,3 \
| tr -d \" \
| awk '{ gsub(/ /,""); print }')
# echo "Download-URL: \"$URL\""

# check installed wireguard version
# echo "1"
$LTI Check if WireGuard is installed
wg version > /dev/nul 2>&1
# echo "2"
# hans > /dev/nul 2>&1
if [[ "$?" != "0" ]]; then
  WG_INSTALLATION_NEEDED=YES
  echo "No WireGuard installation found."
else
  WG_INSTALLATION_NEEDED=NO
  INSTALLED_WG_VERSION=$(wg version | cut -d " " -f 2)
  # INSTALLED_WG_VERSION=v1.0.20210913
  echo "Installed WireGuard version: $INSTALLED_WG_VERSION"
fi

# check for other available WireGuard version
if [[ $WG_INSTALLATION_NEEDED == "NO" ]]; then
  grep "$INSTALLED_WG_VERSION" <<< "$URL" > /dev/nul
  echo $?
  echo "$URL" | grep "$INSTALLED_WG_VERSION" > /dev/nul
  echo $?
fi

# download latest wireguard-version
if [[ $WG_INSTALLATION_NEEDED == "YES" ]]; then
  echo "Download latest wireguard installer from github."
  $LTI Starting download.
  curl -sL $URL -o /tmp/wg.deb
  # echo "curl -sL $URL -o /tmp/wg.deb"
fi

# download latest wireguard-version
# echo "Download latest wiregurad installer"
#curl -sL $URL -o /tmp/wg.deb

$LTI Script started.
$LTI Check if WireGuard is installed
which wg > /dev/nul
if [[ "$?" != "0" ]]; then
  i=1
  while [ $i -le 24 ]
  do
    $LTI Count: $i
    ((i++))
    sudo ping -c1 github.com | grep icmp_req > /dev/nul
    if [[ "$?" == "0" ]]; then
      $LTI Starting download.
      curl -sL $URL -o /tmp/wg.deb && dpkg -i /tmp/wg.deb
      if [[ "$?" == "0" ]]; then
        i=25
        $LTI Installation successful.
        which wg > /dev/nul
        if [[ "$?" == "0" ]]; then
          $LTI WireGuard binary found here: $(which wg)
          EXITCODE=0
        fi
      else
        $LTW Something went wrong. Retry.
      fi
    else
      sleep 5s
    fi
  done
else
  $LTI WireGuard already installed, apply WireGuard config.
  EXITCODE=0
fi
exit $EXITCODE
