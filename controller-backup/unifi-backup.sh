#!/bin/bash

NOW=$(date +"%Y-%m-%d_%H-%M-%S")
DATUM=$(date +"%Y-%m-%d")
STARTTIME=$(date +"%H:%M:%S")
STOREPATH=$(pwd)
LOGPATH=/volume2/syslog/Protokolle/UniFi-Backup
LOGFILE=${NOW}_LogFile.log
LOGGING=${LOGPATH}/${LOGFILE}
CERT=~/.ssh/id_rsa
REMOTEUSER=USERNAME
CONTROLLER=CONTROLLER-IP or HOSTNAME
BACKUPPATH_5=/data/autobackup
BACKUPPATH_6=/srv/unifi/data/backup/autobackup
FIRMWAREPATH=/srv/unifi/data/firmware
CONFIGFILE=/srv/unifi/data/sites/default/config.gateway.json
TARGETPATH=UniFi/Backup

echo Variables:
echo LogFile: ___________ $LOGGING
echo CertFile: __________ $CERT
echo CloudKey-User: _____ $REMOTEUSER
echo Controller: ________ $CONTROLLER
echo Backup-Source v5: __ $BACKUPPATH_5
echo Backup-Source v6: __ $BACKUPPATH_6
echo Firmware-Path: _____ $FIRMWAREPATH
echo Config-File: _______ $CONFIGFILE
echo Store-Path: ________ $TARGETPATH
echo Backup-Folder v5: __ $TARGETPATH/v5
echo Backup-Folder v6: __ $TARGETPATH/v6
echo " "

([ -d $LOGPATH ] || (echo "Folder ${LOGPATH} doesn't exists." && mkdir -p $LOGPATH && echo "Folder ${LOGPATH} created."))
([ -d $TARGETPATH/v5 ] || (echo "Folder $TARGETPATH/v5 doesn't exists." && mkdir -p $TARGETPATH/v5 && echo "Folder $TARGETPATH/v5 created."))
([ -d $TARGETPATH/v6 ] || (echo "Folder $TARGETPATH/v6 doesn't exists." && mkdir -p $TARGETPATH/v6 && echo "Folder $TARGETPATH/v6 created."))
echo "Backup started on $DATUM at $STARTTIME."
echo "Backup started on $DATUM at $STARTTIME." > $LOGGING
echo ""
echo "Copy $BACKUPPATH_5 from $CONTROLLER to $STOREPATH/$TARGETPATH/v5."
echo "" >> $LOGGING
echo "Copy $BACKUPPATH_5 from $CONTROLLER to $STOREPATH/$TARGETPATH/v5." >> $LOGGING
scp -prvi $CERT $REMOTEUSER@$CONTROLLER:$BACKUPPATH_5 $TARGETPATH/v5 2>&1 >> $LOGGING
scpbackupv5=$?
if [ $scpbackupv5 -eq 0 ]; then
    echo "    Done."
    echo "Done." >> $LOGGING
else
    echo "    Error!"
    echo "Error!" >> $LOGGING
fi
echo ""
echo "Copy $BACKUPPATH_6 from $CONTROLLER to $STOREPATH/$TARGETPATH/v6."
echo "" >> $LOGGING
echo "Copy $BACKUPPATH_6 from $CONTROLLER to $STOREPATH/$TARGETPATH/v6." >> $LOGGING
scp -prvi $CERT $REMOTEUSER@$CONTROLLER:$BACKUPPATH_6 $TARGETPATH/v6 2>&1 >> $LOGGING
scpbackupv6=$?
if [ $scpbackupv6 -eq 0 ]; then
    echo "    Done."
    echo "Done." >> $LOGGING
else
    echo "    Error!"
    echo "Error!" >> $LOGGING
fi
echo ""
echo "Copy $FIRMWAREPATH from $CONTROLLER to $STOREPATH/$TARGETPATH."
echo "" >> $LOGGING
echo "Copy $FIRMWAREPATH from $CONTROLLER to $STOREPATH/$TARGETPATH." >> $LOGGING
scp -prvi $CERT $REMOTEUSER@$CONTROLLER:$FIRMWAREPATH $TARGETPATH/ 2>&1 >> $LOGGING
scpfirmware=$?
if [ $scpfirmware -eq 0 ]; then
    echo "    Done."
    echo "Done." >> $LOGGING
else
    echo "    Error!"
    echo "Error!" >> $LOGGING
fi
echo ""
echo "Copy $CONFIGFILE from $CONTROLLER to $STOREPATH/$TARGETPATH."
echo "" >> $LOGGING
echo "Copy $CONFIGFILE from $CONTROLLER to $STOREPATH/$TARGETPATH." >> $LOGGING
scp -pvi $CERT $REMOTEUSER@$CONTROLLER:$CONFIGFILE $TARGETPATH/ 2>&1 >> $LOGGING
scpconfigfile=$?
if [ $scpconfigfile -eq 0 ]; then
    echo "    Done."
    echo "Done." >> $LOGGING
else
    echo "    Error!"
    echo "Error!" >> $LOGGING
fi
# remove eXecute from all autobackup_*-files
find $TARGETPATH -type f -name autobackup_* -exec chmod -x {} \;
ENDTIME=$(date +"%H:%M:%S")
echo ""
echo "Backup finished on $DATUM at $ENDTIME."
echo "" >> $LOGGING
echo "Backup finished on $DATUM at $ENDTIME." >> $LOGGING
grep "volume1/homes" $LOGGING > /dev/null 2>&1
modifylog=$?
echo $modifylog
if [ $modifylog -eq 0 ]; then
    echo "" >> $LOGGING && echo "Script has been executed by Synology task manager." >> $LOGGING
fi
