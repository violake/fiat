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
  * `rake db:create db:migrate`
  * Config folder: ./config/. config files: database.yml, fiat.yml, rabbitmq.yml 
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