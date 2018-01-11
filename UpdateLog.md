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
