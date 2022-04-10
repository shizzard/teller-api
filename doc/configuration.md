# TellerApi application configuration

## Dev environment

Application is configured with ENV variables.

Development environment defaults are defined in the Makefile; you can overwrite any of parameters by prepending it to the `make run` command, e.g.

```
  > TELLER_API_PROCGEN_SECRET_KEY_B36=mysecretkey make run
```

If you want to setup your own dev environment, you can use [DirEnv](https://direnv.net) or similar software. Just put `.envrc` file to the project root (those are ignored with `.gitignore`) and run `direnv allow` once.

Example `.envrc`:

```
export TELLER_API_PROCGEN_SECRET_KEY_B36=mysecretkey
export TELLER_API_PROCGEN_ACCOUNTS_PER_TOKEN_MAX=1
export TELLER_API_PROCGEN_TRANSACTIONS_DAYS_PER_ACCOUNT=90
export TELLER_API_PROCGEN_TRANSACTIONS_PER_DAY_MAX=1
export TELLER_API_HTTP_PORT=8081

export TELLER_API_HTTP_CACHE_LIFETIME_SEC=5
```

## Test environment

Environment variables are reused in integration test suite, described in [tests](/doc/tests.md) page. With this approach you can easily run the same tests in different configurations (as long as tests are executed with `make check` or sub-command; it is possible to customize this behavior though).

## Production environment

If you imagine this application is going to run in production, you can easily reuse environment variables to pack the application into docker container. With this approach it will be configurable in the same way.

## Environmant variables

Most of variables are self-describing; If you don't understand what exact variable stands for, see [application](/doc/application.md) documentation.

- `TELLER_API_LOGGER_LEVEL`:

  Logger level (file backend)

- `TELLER_API_LOGGER_DIR`:

  Log directory (`_log` by default)

- `TELLER_API_PROCGEN_SECRET_KEY_B36`:

  Secret key

- `TELLER_API_PROCGEN_SECRET_KEY_B36_BASE`:

  Secret key bit-width

- `TELLER_API_PROCGEN_ACCOUNTS_ID_BASE`:

  Account id bit-width

- `TELLER_API_PROCGEN_ACCOUNTS_ENROLLMENT_ID_BASE`:

  Enrollment id bit-width

- `TELLER_API_PROCGEN_ACCOUNTS_ROUTING_NUMBERS_ACH`:

  Routing numbers bit-width

- `TELLER_API_PROCGEN_ACCOUNTS_PER_TOKEN_MAX`:

  Maximum accounts per auth token

- `TELLER_API_PROCGEN_TRANSACTIONS_ID_BASE`:

  Transaction id bit-width

- `TELLER_API_PROCGEN_TRANSACTIONS_DAYS_PER_ACCOUNT`:

  Exact amount of days generated per account

- `TELLER_API_PROCGEN_TRANSACTIONS_PER_DAY_MAX`:

  Maximum amount of transactions per day

- `TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MIN`:

  Generated transaction amount minimum

- `TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MAX`:

  Generated transaction amount maximum

- `TELLER_API_PROCGEN_TRANSACTIONS_STATUS_POSTED_CHANCE`:

  A chance generated transaction will have `posted` status

- `TELLER_API_PROCGEN_TRANSACTIONS_PROCESSING_STATUS_COMPLETE_CHANCE`:

  A chance generated transaction will have `complete` processing status

- `TELLER_API_HTTP_PROTO`:

  HTTP links protocol (https is not supported)

- `TELLER_API_HTTP_HOST`:

  HTTP links host

- `TELLER_API_HTTP_PORT`:

  HTTP links port

- `TELLER_API_HTTP_CACHE_LIMIT`:

  In-memory cache limit (one slot per token)

- `TELLER_API_HTTP_CACHE_LIFETIME_SEC`:

  In-memory cache lifetime in seconds