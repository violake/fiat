=====19 Feburary 2018========

# withdrawal reconciliation email to Vicky and Una

## modify /home/app/fiat/shared/grab_transfer-out.sh

```
USER_EMAIL=('vicky.zhang@acx.io' 'una.fu@acx.io')
```

## modify /home/app/fiat/shared/send_daily_report.sh

```
USER_EMAIL=('vicky.zhang@acx.io' 'una.fu@acx.io')
```

=====13 Feburary 2018========

# grab script email subject change

## modify grab.sh

add line before DATE
```
EMAIL_DATE=$(TZ=Australia/Melbourne date +"%d-%m-%Y")
```

edit line
from
```
./fiatCLI.rb exportErrorCSV -t "$TIME" -e ${USER_EMAIL[@]} -b "$body\nPlease find the attachment." >> $LOG_FILE
```
to
```
./fiatCLI.rb exportErrorCSV -t "$EMAIL_DATE" -e ${USER_EMAIL[@]} -b "$body\nPlease find the attachment." >> $LOG_FILE
```

## modify grab_transfer-out.sh

add line before DATE
```
EMAIL_DATE=$(TZ=Australia/Melbourne date +"%d-%m-%Y")
```

edit line
from
```
SUBJECT="Withdrawal import result $TIME"
```
to
```
SUBJECT="Withdrawal import result $EMAIL_DATE"
```


=====1 Feburary 2018========

# deploy withdrawal reconciliation to FIAT server

## build

### old way

```
git pull origin release
bundle exec install --path=vendor/bundle
bundle exec rake build
```

### new way

use the package built by jenkins

## disable cronjob

```
server > crontab -e
#0 21-23,0-9 * * * export PATH=/home/app/.rbenv/shims:/home/app/.rbenv/bin:/usr/bin:$PATH; eval "$(rbenv init -)"; cd /home/app/fiat/shared && RAILS_ENV=production ./grab.sh
```

## stop fiat daemons

```
server > supervisorctl stop fiatd fiatd_resend
```

## deploy to the fiat server

## modify fiat.yml
```
...
-  payment_type: ["bank"]
+  transfer_type: ["bank"]
...
westpac:
  bank_account_regex: \d{12}|\d{14}
-  import_filter_categories: ["DEP", "CREDIT", "ATM", "OTHER", "DEBIT", "FEE"]
+  import_transfer_in_categories: ["DEP", "CREDIT", "ATM", "OTHER", "DEBIT", "FEE"]
+  import_transfer_out_categories: ["PAYMENT"]    -- white list for import withdraw of westpac statement
+  transfer_out_withdrawal_regex: \d+             -- regex for capture withdraw ids
...
```

## db migration

20180103042617_create_transfer_out
20180110031505_edit_column_payment_transaction_id_to_deposits
20180110032413_change_tablename_transfer_ins_to_payments
20180110032917_edit_column_payment_type_to_transfer_ins
20180112002249_add_column_lodged_amount_and_email_to_tranfer_out
20180112055947_create_withdraws
20180115053017_add_column_fee_to_transfer_outs

### migrate after deploy release package to server

```
local > ssh server
server > mkdir /home/app/fiat/current/db/migrate
server > exit
local > scp 20180103042617_create_transfer_out server:/home/app/fiat/current/db/migrate
local > scp 20180110031505_edit_column_payment_transaction_id_to_deposits serve:/home/app/fiat/current/db/migrate
local > scp 20180110032413_change_tablename_transfer_ins_to_payments serve:/home/app/fiat/current/db/migrate
local > scp 20180110032917_edit_column_payment_type_to_transfer_ins serve:/home/app/fiat/current/db/migrate
local > scp 20180112002249_add_column_lodged_amount_and_email_to_tranfer_out serve:/home/app/fiat/current/db/migrate
local > scp 20180112055947_create_withdraws serve:/home/app/fiat/current/db/migrate
local > scp 20180115053017_add_column_fee_to_transfer_outs serve:/home/app/fiat/current/db/migrate

local > ssh server
server > cd /home/app/fiat/current
server > bin/rake db:migrate
```

## start daemon

```
server > supervisorctl start fiatd fiatd_resend
```

## check daemon is running and daemon error log if all green continue

```
server > supervisorctl status
...
server > tail -100 /home/app/fiat/shared/log/fiatd-error.log
server > tail -100 /home/app/fiat/shared/log/fiatd_resend-error.log
```


## add new cronjob

### copy the new cronjob of withdrawal reconciliation

```
server > cp /home/app/fiat/current/grab_transfer-out.sh /home/app/fiat/shared
```

### edit crontab

```
server > crontab -e
0 21-23,0-9 * * * export PATH=/home/app/.rbenv/shims:/home/app/.rbenv/bin:/usr/bin:$PATH; eval "$(rbenv init -)"; cd /home/app/fiat/shared && RAILS_ENV=production ./grab.sh
0 21-23,0-9 * * * export PATH=/home/app/.rbenv/shims:/home/app/.rbenv/bin:/usr/bin:$PATH; eval "$(rbenv init -)"; cd /home/app/fiat/shared && RAILS_ENV=production ./grab_transfer-out.sh
```

## deploy done


=====29 January 2018========

# auto test for fiat

## edit database.yml in testing server only

```
test:
  <<: *default
  database: db(same name as production)
```

## run test and check both import result and rspec result

```
./auto_test.sh

[TASK]test start!
[STEP]generate acx test data
[STEP]generated
[STEP]import statements
[EXPECT] import result:
{:imported=>4, :ignored=>0, :error=>1, :rejected=>1, :filtered=>0, :sent=>3}
{:imported=>2, :ignored=>0, :error=>0, :rejected=>0, :filtered=>9, :sent=>2}
{:imported=>7, :ignored=>0, :error=>2, :filtered=>4, :sent=>5}
[RESULT]
{:imported=>4, :ignored=>0, :error=>1, :rejected=>1, :filtered=>0, :sent=>3}
{:imported=>2, :ignored=>0, :error=>0, :rejected=>0, :filtered=>9, :sent=>2}
{:imported=>7, :ignored=>0, :error=>2, :filtered=>4, :sent=>5}
[STEP]imported
[STEP]check test result
[STEP]***************************
[RESULT] Passed all the tests!
[STEP]***************************
[STEP]destroy fiat test data
[STEP]destroy acx test data
[TASK]test done!
```


=====25 January 2018========

# script for withdraw reconciliation

## copy withdrawal script to shared folder

```
cp grab_transfer-out.sh /home/app/fiat/shared/
```

## add to crontab

```
crontab -e
0 21-23,0-9 * * * export PATH=/home/app/.rbenv/shims:/home/app/.rbenv/bin:/usr/bin:$PATH; eval "$(rbenv init -)"; cd /home/app/fiat/shared && RAILS_ENV=production ./grab_transfer-out.sh
```


=====22 January 2018========

# update fiatCLI export to email

## modify grab.sh

- USER_EMAIL=abc@aaa.com
+ USER_EMAIL=('abc@aaa.com' 'ddd@sss.cn')

- ./fiatCLI.rb exportErrorCSV -e $USER_EMAIL -b "$body\nPlease find the attachment." >> $LOG_FILE
+ ./fiatCLI.rb exportErrorCSV -e ${USER_EMAIL[@]} -b "$body\nPlease find the attachment." >> $LOG_FILE



=====11 January 2018========
# add configuration for withdrawal reconciliation

fiat.yml
## name change

...
-  payment_type: ["bank"]
+  transfer_type: ["bank"]
...
-  import_filter_categories: ["DEP", "CREDIT", "ATM", "OTHER", "DEBIT", "FEE"]
+  import_transfer_in_categories: ["DEP", "CREDIT", "ATM", "OTHER", "DEBIT", "FEE"]
...

## add new configuration

...
westpac:
  ...
  import_transfer_out_categories: ["PAYMENT"]    -- white list for import withdraw of westpac statement
  transfer_out_withdrawal_regex: \d+             -- regex for capture withdraw ids
...
