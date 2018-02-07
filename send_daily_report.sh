#!/bin/bash

APP_PATH=/home/app/fiat/current
USER_EMAIL=('vicky.zhang@acx.io')
LOG_FILE=/home/app/fiat/shared/history/grab_transfer-out.log

TIME=$(date +"%d-%m-%Y %H:%M")
ZONENAME=Australia/Melbourne
DATE=$(TZ=Australia/Melbourne date --date='today' +'%Y%m%d')

cd $APP_PATH
log="$(./fiatCLI.rb exportTransferOutDailyReportCSV  -z $ZONENAME -e ${USER_EMAIL[@]} -d $DATE)"
body="\n$TIME\n$log\n\n"
echo -e $body >> $LOG_FILE
echo 'done'