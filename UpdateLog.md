=====11 January 2018========
# add configuration for withdrawal reconciliation

fiat.yml

...
westpac:
  ...
  import_transfer_out_categories: ["PAYMENT"]    -- white list for import withdraw of westpac statement
  transfer_out_withdrawal_regex: \d+             -- regex for capture withdraw ids
...
