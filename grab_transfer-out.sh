#!/bin/bash                                                                                                                                                                                    
                     
APP_PATH=/home/app/fiat/shared

key_westpac=1Nf1d6OL01X6KbSBPW5UNAU20N67zXbR5_-uZe3DHuWc
WESTPAC_ACCOUNT='033152-468666'
USER_EMAIL=('roger.fang@acx.io')

DATE=$(date +"%d-%m-%y_%H-%M")
TIME=$(date +"%d-%m-%y %H:%M")
ZONE=$(TZ=Australia/Melbourne date +'%z'| cut -c1-3)':00'
LOG_FILE=/home/app/fiat/shared/history/grab_transfer-out.log
WESTPAC_NAME='Westpac_transfer-out'
WESTPAC_HISTORY=/home/app/fiat/shared/history/westpac

cd $APP_PATH
mkdir -p $WESTPAC_HISTORY

curl -L "https://docs.google.com/spreadsheets/d/$key_westpac/export?exportFormat=csv" > /tmp/${WESTPAC_NAME}.csv 
time_a="$TIME import Westpac Transfer-out"
cd $APP_PATH
log_a="$(./fiatCLI.rb importTransferOutCSV /tmp/$WESTPAC_NAME.csv -t $ZONE -a $WESTPAC_ACCOUNT)"
cp /tmp/${WESTPAC_NAME}.csv $WESTPAC_HISTORY/${WESTPAC_NAME}_$DATE.csv


body="\n$time_a\n$log_a\n\n"

echo -e $body >> $LOG_FILE

./fiatCLI.rb exportTransferOutErrorCSV -e ${USER_EMAIL[@]} -b "$body\nPlease find the attachment." >> $LOG_FILE
