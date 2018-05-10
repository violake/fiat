# README

## What is this repository for? ###

### Quick summary

Fiat is a fiat payment import and reconcile system by sending payment to Comsumer and auto accept deposits.

### Versions

 * 1.0.0 

## How do I get set up? ###

### Summary of set up
  
Fiat is a Web Application with a daemon which needs to 

  * import payments via csv
  * show payments status and matched deposit
  * send payment to ACX for reconciliation via MQ
  * subscribe to MQ handle rpc call for customer deposit code generating
  * manage long running processes (supvervisord)
  * have access to database

### Configuration

Config files are in `config` directory ending with `.yml`.

### Dependencies

  * amqp-tools
  * supervisor
  * libmariadbclient-dev for gem `mysql2`
  * rails 5.1.4

### How to run tests

rspec

### Deployment instructions


  * Config folder: ./config/. config files: application.yml, database.yml, fiat.yml, rabbitmq.yml, transition_deposits.yml
  *               in database.yml, modify "fiatd: database:" the same as production when it's deployed to production server

application.yml -- for session shared with ACX

database.yml    -- deployment, production, test for rails api; fiatd for fiat daemon to update payments according to message ACX replied

fiat.yml
  payment_type: ["bank"]            -- type of payment, for now only bank
  log_level: DEBUG                  -- log level
  archive_limit: 7                  -- data could be archived (over "7" days)
  search_day_diff: 3                -- when searching payments using filter date, payments "3" days ago from the filter date will be returned
  member_whitelist: ["1", "2"]      -- member_ids that could use apis
  resend_frequence: 10              -- the fiat resend daemon payment resend frequence: run 'resend' every "10" minutes
  fund_refresh_cron: "5 0 * * *"    -- the fiat resend daemon bank account refresh cron frequence: 0:05 everyday
  resend_lag: 60                    -- resend payments that have no reply for over "60" minutes
  resend_times: 3                   -- limitation for resend times
  rails_env: "development"          -- for fiat daemon to start normally in development mode
  bank_accounts_filter: ["honesty_point", "acceptable_amount"]  -- filter for bank accounts' detail
  customer_code_mask: "pgh27fds8i"  -- for fiat generate customer code with this mask
  customer_code_regex: '[\d]{1}[a-z0-9]{5,11}'  -- for fiat to match the customer code from bank description

rabbitmq.yml    -- username, password, queue's names for fiat to use RabbitMQ server

fund_source.yml -- bank accounts sync from ACX, do not need to edit it when deploying

transition_deposits.yml -- a filter for transition period that make sure all the code in description is customer code. Certain record's status will be error if the code is in this file


  * `rake init:fiat_queues`
  * Database configuration

```
  rake db:create 
  rails generate paper_trail:install
  rake db:migrate

```



  * Configure supervisor refer to `contribs/supervisor.d/fiatd.conf` and `contribs/supervisor.d/fiatd_resend.conf`
  edit these config file and copy to supervisor's config folder, call supervisor to read new config files, update and check status
```
cp contribs/supervisor.d/*.conf /etc/supervisor/conf.d


supervisorctl reread
supervisorctl update
supervisorctl status

fiatd                            RUNNING   pid 1070, uptime 0:47:11
fiatd_resend                     RUNNING   pid 1836, uptime 0:47:18
```

## Contribution guidelines ###

* Writing tests
* Code review
* Other guidelines

## Who do I talk to? ###

Roger Fang <roger.fang@acx.io>

## Appendix

### CLI


### Enum reference

  enum payment result: {:unreconciled, :reconciled, :error}

  enum payment status: {:new, :sent, :archived}

### How to start

Fiat Rails Server

 `rails s`

Fiat daemon

```
supervisorctl start fiatd
supervisorctl start fiatd_resend
```

FiatCLI

 `./fiatCLI`

### Cronjob

Auto grab google doc(csv) and import it by calling fiatCLI. Save the csv file in history

copy grab.sh to "shared" folder for the first deployment

modify the "path_to" of grab.sh

APP_PATH=path_to/fiat/
LOG_FILE=path_to/history/grab.log
BEYONG_HISTORY=path_to/history/beyond
WESTPAC_HISTORY=path_to/history/westpac

Change the key of google docs

key_beyond=1rOvx90qcMiLWSAL-aUO2qmp0p4VEGTzSUsIeQZYpR24
key_westpac=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

Edit the user's email ( the person who import the bank statements)

USER_EMAIL=xxx@mail.com

command:
```
sh grab.sh
```