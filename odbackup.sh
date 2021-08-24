#!/bin/sh -x
#
# Robin O'Donoghue, May 2012
# bash script to back the OpenDirectory database
# creates DMG file on local desktop, then ditto copies to afs4
#
# August 2012 - issue with Crontab jobs on this box, won't cron jobs but craps out with Console error: 
# example: 14/08/2012 23:00:00 com.apple.launchd[1] (0x10dcf0.cron[53176]) Could not setup Mach task special port 9: (os/kern) no access 
# Andi has logged with Jigsaw24 to investigate...  

# Set variables
NOW=$(date +"%Y%m%d")
RECOVER="/Users/USERNAME/Desktop/od-dc1databackups"
TEMP_FILE="/tmp/od-dc1backupfile"
BACKUPS="/Users/USERNAME/Desktop/od-dc1databackups"
#PRODAFS4=`df -h | grep Production | awk '{print $6,$7}'`
PRODAFS4="/Volumes/Production (afs4)"

# check that Production (afs4) volume is mounted

/bin/df | grep "$PRODAFS4"

if [ $? != 1 ]; then
        echo ' ' >> /dev/null
else
# df failed so its not currently mounted
        if [ -d "$PRODAFS4" ]; then
                rmdir "$PRODAFS4"
        fi

        MOUNT_POINT="/Volumes/Production (afs4)"
        mkdir -v "$MOUNT_POINT" >> "$TEMP_FILE" 2>&1
        /sbin/mount_afp "afp://USERNAME@ADDRESS/Production (afs4)" "$MOUNT_POINT"
fi

SERVERBUILDS="$PRODAFS4/Editorial Systems/Builds server/Server Details/od-dc1 data backup"

# Backup Open Directory
DAY=`date ''+%u''`
OD_BACKUP="$BACKUPS/od_backup "$NOW""
TS=`date ''+%Y%m%d''`

echo "dirserv:backupArchiveParams:archivePassword = ********* " > $OD_BACKUP
echo "dirserv:backupArchiveParams:archivePath = $BACKUPS/ODDC1_archive_$TS" >> $OD_BACKUP
echo "dirserv:command = backupArchive" >> $OD_BACKUP
 
/usr/sbin/serveradmin command < $OD_BACKUP

/bin/ls -l -rt | tail -1 > $TEMP_FILE

# sleep for 20 seconds to allow file to write to disk before ditto

sleep 20

/usr/bin/ditto --rsrc "$BACKUPS/ODDC1_archive_$TS.sparseimage" "$SERVERBUILDS/ODDC1_archive_$TS.sparseimage"
        
/bin/rm "$OD_BACKUP"

exit 0
