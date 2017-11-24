#!/bin/bash                                                                                                                                                                                    

#source /home/app/.deployrc                     
APP_PATH=path_to/fiat/

key_beyond=1rOvx90qcMiLWSAL-aUO2qmp0p4VEGTzSUsIeQZYpR24
key_westpac=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

DATE=$(date +"%d-%m-%y")
ZONE=$(TZ=Australia/Melbourne date +'%z'| cut -c1-3)':00'

BEYOND_ACCOUNT='805022-03651883'
WESTPAC_ACCOUNT='033152-468666'

BEYOND_NAME=Beyond_statement
WESTPAC_NAME=Westpac_statement

BEYONG_HISTORY=path_to/history/beyond
WESTPAC_HISTORY=path_to/history/westpac

mkdir -p $BEYONG_HISTORY
mkdir -p $WESTPAC_HISTORY

curl -L "https://docs.google.com/spreadsheets/d/$key_beyond/export?exportFormat=csv" > /tmp/$BEYOND_NAME.csv 
cd $APP_PATH && ./fiatCLI.rb importCSV /tmp/$BEYOND_NAME.csv -t $ZONE -a $BEYOND_ACCOUNT
cp /tmp/$BEYOND_NAME.csv $BEYONG_HISTORY/$BEYOND_NAME_$DATE.csv

curl -L "https://docs.google.com/spreadsheets/d/$key_westpac/export?exportFormat=csv" > /tmp/$WESTPAC_NAME.csv 
cd $APP_PATH && ./fiatCLI.rb importCSV /tmp/$WESTPAC_NAME.csv -t $ZONE -a $WESTPAC_ACCOUNT
cp /tmp/$WESTPAC_NAME.csv $WESTPAC_HISTORY/$WESTPAC_NAME_$DATE.csv