#!/bin/bash                                                                                                                                                                                    

#source /home/app/.deployrc                     
APP_PATH=/home/app/fiat/current/

key_beyond=1ueNaxOIAMcs2UgakORik6Q4sWb1I_xSoMGuonyKORyY
key_westpac=1d_xD0N6oCsRpPGGVtVYn3UXZh5krJMW301j0J1ZpsJ8

DATE=$(TZ=Australia/Melbourne date +"%d-%m-%Y_%H-%M")
TIME=$(TZ=Australia/Melbourne date +"%d-%m-%Y %H:%M")
ZONE=$(TZ=Australia/Melbourne date +'%z'| cut -c1-3)':00'

BEYOND_ACCOUNT='805022-03651883'
WESTPAC_ACCOUNT='033152-468666'

LOG_FILE=/home/app/fiat/history/grab.log

BEYOND_NAME='Beyond_statement'
WESTPAC_NAME='Westpac_statement'

BEYONG_HISTORY=/home/app/fiat/history/beyond
WESTPAC_HISTORY=/home/app/fiat/history/westpac

USER_EMAIL=('vicky.zhang@acx.io' 'una.fu@acx.io')

mkdir -p $BEYONG_HISTORY
mkdir -p $WESTPAC_HISTORY

curl -L "https://docs.google.com/spreadsheets/d/$key_beyond/export?exportFormat=csv" > /tmp/${BEYOND_NAME}.csv 
time_a="$TIME import Beyond Statement"
cd $APP_PATH
log_a="$(./fiatCLI.rb importCSV /tmp/${BEYOND_NAME}.csv -t $ZONE -a $BEYOND_ACCOUNT)"
cp /tmp/${BEYOND_NAME}.csv $BEYONG_HISTORY/${BEYOND_NAME}_$DATE.csv

curl -L "https://docs.google.com/spreadsheets/d/$key_westpac/export?exportFormat=csv" > /tmp/${WESTPAC_NAME}.csv 
time_b="$TIME import Westpac Statement"
log_b="$(./fiatCLI.rb importCSV /tmp/$WESTPAC_NAME.csv -t $ZONE -a $WESTPAC_ACCOUNT)"
cp /tmp/${WESTPAC_NAME}.csv $WESTPAC_HISTORY/${WESTPAC_NAME}_$DATE.csv



body="\n$time_a\n$log_a\n\n$time_b\n$log_b\n"

echo -e $body >> $LOG_FILE

./fiatCLI.rb exportErrorCSV -t "$TIME" -e ${USER_EMAIL[@]} -b "$body\nPlease find the attachment." >> $LOG_FILE
