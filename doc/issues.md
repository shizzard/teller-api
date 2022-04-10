# TellerApi applcation known issues

## `TellerApiProcgen`

- [`TellerApiProcgen.Account`](/apps/teller_api_procgen/lib/teller_api_procgen_account.ex) depends on transactions (to calculate balance/ledger), thats why we cannot generate account without generating full list of transactions.

- Cache entries expiration should be set to the start of the next day, since the data is static.

- [`TellerApiProcgen.Transaction`](/apps/teller_api_procgen/lib/teller_api_procgen_transaction.ex) is not fully proc-generated, thus the adjustments needed (dates are generated based on currrent date, balances/ledgers are calculated based on other transactions in a list).

- [`TellerApiProcgen.Transaction`](/apps/teller_api_procgen/lib/teller_api_procgen_transaction.ex) has one single side-effect: current day is calculated instead of being configured.

- Structs `from_string` functions should be refactored (lots of shared code).

- [`TellerApiProcgen.Token`](/apps/teller_api_procgen/lib/teller_api_procgen_token.ex) might be optimized not to generate all accounts at once (be lazy).

## `TellerApiHttp`

- Logging (access log) is cery scarce and is not production-ready.

- Cowboy listeners should be configured properly for production environments.

- Cowboy does not send charset in the `content-type` header for some reason, should be fixed.

- 404 errors should be implemented with `resource_exists` cowboy handler, but it is much easier to go straight to the handler because of the data nature (procedural generation).

- Account resources (details, balances, etc.) are a mostly a boilerplate.

- GET parameters are validated in a very simple way. In real-world application there sould be generalized validator.

## Tests

- There is no test for day change (check if it will generate a new set of transactions, keeping everything else the same).