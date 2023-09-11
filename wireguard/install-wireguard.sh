#!/bin/vbash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LTN="logger -t wg-installer"
LTI="logger -p info -t wg-installer"
LTW="logger -p warn -t wg-installer"
LTE="logger -p error -t wg-installer"
WR="/opt/vyatta/sbin/vyatta-cfg-cmd-wrapper"
EXITCODE=42

################

# identify file path
CANON=$(cd -P -- "$(dirname -- "$0")" && printf '%s\n' "$(pwd -P)/$(basename -- "$0")")

# identify hardware (USG3 / USG4)
#MODEL=$(info | grep -i "model" | cut -d : -f 2,3 | awk '{ gsub(/ /,""); print }')
MODEL=THISISMYMODEL
if [[ $MODEL == "UniFi-Gateway-4" ]]; then
  HARDWARE=ugw4
else
  if [[ $MODEL == "UniFi-Gateway-3" ]]; then
    HARDWARE=ugw3
  else
    echo "Hardware not supported."
    echo "Please remove file \"$CANON\"."
    exit 23
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
#echo "1"
wg version > /dev/nul 2>&1
#echo "2"
#hans > /dev/nul 2>&1
if [[ "$?" != "0" ]]; then
  WG_INSTALLATION_NEEDED=YES
  echo "No WireGuard installation found."
else
  WG_INSTALLATION_NEEDED=NO
#  INSTALLED_WG_VERSION=$(wg version | cut -d " " -f 2)
  INSTALLED_WG_VERSION=v1.0.20210913
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
  #curl -sL $URL -o /tmp/wg.deb
  echo "curl -sL $URL -o /tmp/wg.deb"
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
