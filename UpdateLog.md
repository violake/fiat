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
