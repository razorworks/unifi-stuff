#!/bin/bash

NOW=$(date +"%Y-%m-%d_%H-%M-%S")
LOGPATH=/volume2/syslog/Protokolle/UniFi-Backup
LOGFILE=${NOW}_LogFile.log
LOGGING=${LOGPATH}/${LOGFILE}
CERT=~/.ssh/id_rsa
REMOTEUSER=USERNAME
CONTROLLER=CONTROLLER-IP or HOSTNAME
BACKUPPATH=/data/autobackup
FIRMWAREPATH=/srv/unifi/data/firmware
CONFIGFILE=/srv/unifi/data/sites/default/config.gateway.json
TARGETPATH=UniFi

echo Variables:
echo LogFile: ________ $LOGGING
echo CertFile: _______ $CERT
echo CloudKey-User: __ $REMOTEUSER
echo Controller: _____ $CONTROLLER
echo Backup-Path: ____ $BACKUPPATH
echo Firmware-Path: __ $FIRMWAREPATH
echo Config-File: ____ $CONFIGFILE
echo Store-Path: _____ $TARGETPATH
echo " "

([ -d $LOGPATH ] || (echo "Folder ${LOGPATH} doesn't exists." && mkdir -p $LOGPATH && echo "Folder ${LOGPATH} created."))
([ -d $TARGETPATH ] || (echo "Folder ${TARGETPATH} doesn't exists." && mkdir -p $TARGETPATH && echo "Folder ${TARGETPATH} created."))
echo "Copy ${BACKUPPATH} to ${TARGETPATH}."
scp -prvi $CERT $REMOTEUSER@$CONTROLLER:$BACKUPPATH $TARGETPATH/ 2>&1>$LOGGING
echo "Copy ${FIRMWAREPATH} to ${TARGETPATH}."
scp -prvi $CERT $REMOTEUSER@$CONTROLLER:$FIRMWAREPATH $TARGETPATH/ 2>&1>>$LOGGING
echo "Copy ${CONFIGFILE} to ${TARGETPATH}."
scp -pvi $CERT $REMOTEUSER@$CONTROLLER:$CONFIGFILE $TARGETPATH/ 2>&1>>$LOGGING
echo "DONE." >> $LOGGING
