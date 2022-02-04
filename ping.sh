#!/bin/bash
# Script: ping.sh
# Purpose: Pings the router to check the connectivity. Logs everything into logs. If the Wi-Fi is down it ups the interface. Written for Raspberry Pi 2/3/4, but it will work in ant Linux distro. Just change the paths. 
# Author: Adrian Ambroziak <sysadmin.info.pl> under GPL v3.x+

# Add the below row in /etc/crontab
#*/2 * * * * pi /bin/bash -x /home/pi/ping.sh > /var/log/pinglog/log-`date +\%Y-\%m-\%d_\%H:\%M`.log 2>&1

pidfile=/home/pi/ping.sh.pid
pidfiletmp=/home/pi/ping.sh.pidfile.tmp
data=$( date +"%Y-%m-%d %H:%M:%S" )
data1=$( date +"%Y-%m-%d-%H:%M" )
TEXT1="The packet loss is consistently over 5%"
TEXT2="The packet loss is less than 5%."
concatenate="${data} ${TEXT2}"
FILE=/tmp/ping_log

#create a pidfile, skip if exists.
if [ -f "$pidfiletmp" ]; then
  exit
else
  echo $$ > $pidfiletmp

# ping with flood check -f (value is 5) tries the ping sixty times -c 60
ping -t 5 -c 60 192.168.1.1 > /tmp/ping_drop.tmp
# put date into ping_drop_all log
date >> /tmp/ping_drop_all
# put content from /tmp/ping_drop.tmp into /tmp/ping_drop.tmp that contains logs with the date 
/bin/cat /tmp/ping_drop.tmp >> /tmp/ping_drop.tmp

# Cut the loss value from the /tmp/ping_drop_all
LOSS=`grep transmitted  /tmp/ping_drop.tmp | awk -F "," '{print $3}' |cut -c 2- |awk -F "%" '{print $1}'`

if [[ "$LOSS" =~ ^[0-9]+$ ]]; then
  # if $LOSS is not a number then end this script
  echo $LOSS% procent `date` >> /tmp/ping_loss_all.log
  #if variable is equal 0% then delete the ping.sh.pid file and log to the file
  if [ "$LOSS" -le 1 ]; then
  ## Deleting the ping.sh.pid file
  trap "rm -f -- '$pidfile'" EXIT
   ## Deleting the ping_log file
   if [ -f "$FILE" ]; then
    echo "$FILE exists."
    echo "removing ping_log ..."
    rm -f /tmp/ping_log
   else
    echo "$FILE does not exist."
   fi
   
   ## Creating ping_log
   touch /tmp/ping_log
   
   ## Clearing ping_log
   echo "" > /tmp/ping_log
   
   ## create a directory for a log and save a log
   mkdir -p /home/pi/ping_drop_check_reports_4_percent
   cd /home/pi/ping_drop_check_reports_4_percent
   touch msg_4_percent.txt
   echo $concatenate > /home/pi/ping_drop_check_reports_4_percent/msg_4_percent.txt

#if variable is less or equal 49 % loss then log it.
elif [ "$LOSS" -le 49 ]; then
  rm -f $pidfile
  mkdir -p /home/pi/ping_drop_check_reports_over_5_percent
  cd /home/pi/ping_drop_check_reports_over_5_percent
  touch msg_over_5_percent.txt
  echo $TEXT1 > /home/pi/ping_drop_check_reports_over_5_percent/msg_over_5_percent.txt
  tail -2 /tmp/ping_drop.tmp |head -1 >> /home/pi/ping_drop_check_reports_over_5_percent/msg_over_5_percent.txt

#if variable is greater than 50% loss then switch the traffic.
else
    if [ -f $pidfile ]; then
      if [ "`grep "Connection timed out" /tmp/ping_log | awk -F " " '{print $8}'`" = 'Connection' ]; then
        rm -f $pidfile
      fi
      rm -f $pidfiletmp
      exit
      else
        echo $$ > "$pidfile"
        ## Deleting the ping_log file
        if [ -f "$FILE" ]; then
          echo "$FILE exists."
          echo "removing ping_log ..."
          rm -f /tmp/ping_log
        else
          echo "$FILE does not exist."
        fi
      ## Creating ping_log
      touch /tmp/ping_log
      cat /tmp/ping_log > /home/pi/"ping_log_${data1}"
      fi
    fi
    else
    # switch the wi-fi
      nmcli radio wifi off
      nmcli radio wifi on
      rm $pidfiletmp
      exit
    fi
  rm $pidfiletmp
fi
