# README

## What is this repository for? ###

### Quick summary

Fiat is a fiat payment import and reconcile system by sending payment to ACX and auto accept deposits.

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

  * `rake init:fiat_queues`
  * Database configuration

```
  rake db:create 
  rails generate paper_trail:install
  rake db:migrate

```

  * Config folder: ./config/. config files: application.yml, database.yml, fiat.yml, rabbitmq.yml 
  *               in database.yml, modify "fiatd: database:" the same as production when it's deployed to production server

```
application.yml -- for session shared with ACX

database.yml    -- deployment, production, test for rails api; fiatd for fiat daemon to update payments according to message ACX replied

fiat.yml
  payment_type: ["bank"]            -- type of payment, for now only bank
  log_level: DEBUG                  -- log level
  archive_limit: 7                  -- data could be archived (over "7" days)
  search_day_diff: 3                -- when searching payments using filter date, payments "3" days ago from the filter date will be returned
  member_whitelist: ["1", "2"]      -- member_ids that could use apis
  resend_frequence: 10              -- the fiat resend daemon payment resend frequence: run 'resend' every "10" minutes
  fund_refresh_cron: "5 0 * * *"  -- the fiat resend daemon bank account refresh cron frequence: 0:05 everyday
  resend_lag: 60                    -- resend payments that have no reply for over "60" minutes
  rails_env: "production"           -- for fiat daemon to start normally 

rabbitmq.yml    -- username, password, queue's names for fiat to use RabbitMQ server

fund_source.yml -- bank accounts sync from ACX not needed when deploy
```

  * Configure supervisor refer to `contribs/supervisor.d/fiatd.conf`


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

 `fiat_daemon`
 
 `fiat_resend_daemon`

FiatCLI

 `./fiatCLI`