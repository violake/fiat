echo "[TASK]test start!"
ZONE=$(TZ=Australia/Melbourne date +'%z'| cut -c1-3)':00'
BEYOND_ACCOUNT='805022-03651883'
WESTPAC_ACCOUNT='033152-468666'
ACX_PATH=/home/app/acx/current
FIAT_PATH=/home/app/fiat/current

# ACX database rake test data
echo "[STEP]generate acx test data"
cd $ACX_PATH
bundle exec rake test_data:destroy_fiat_data || { echo "[ERROR]command failed"; exit 1; }
bundle exec rake test_data:generate_fiat_data || { echo "[ERROR]command failed"; exit 1; }
cd $FIAT_PATH
bundle exec rake test_data:destroy_fiat_data || { echo "[ERROR]command failed"; exit 1; }

echo "[STEP]generated"

echo "[STEP]import statements"
echo "[EXPECT] import result:
{:imported=>4, :ignored=>0, :error=>1, :rejected=>1, :filtered=>0, :sent=>3}
{:imported=>2, :ignored=>0, :error=>0, :rejected=>0, :filtered=>9, :sent=>2}
{:imported=>7, :ignored=>0, :error=>2, :filtered=>4, :sent=>5}"
echo "[RESULT]"

./fiatCLI.rb importCSV spec/auto_test/Beyond_statement_auto.csv  -t $ZONE -a $BEYOND_ACCOUNT || { echo "[ERROR]command failed"; exit 1; }
./fiatCLI.rb importCSV spec/auto_test/Westpac_statement_auto.csv -t $ZONE -a $WESTPAC_ACCOUNT || { echo "[ERROR]command failed"; exit 1; }
./fiatCLI.rb importTransferOutCSV spec/auto_test/Westpac_statement_auto.csv -t $ZONE -a $WESTPAC_ACCOUNT || { echo "[ERROR]command failed"; exit 1; }
echo "[STEP]imported"
sleep 5
echo "[STEP]check test result"
echo "[STEP]***************************"
bundle exec rake test_data:check_result || { echo "[ERROR]command failed"; exit 1; }
echo "[STEP]***************************"
echo "[STEP]destroy fiat test data"
bundle exec rake test_data:destroy_fiat_data || { echo "[ERROR]command failed"; exit 1; }
echo "[STEP]destroy acx test data"
bundle exec rake test_data:destroy_fiat_data || { echo "[ERROR]command failed"; exit 1; }

echo "[TASK]test done!"