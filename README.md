# TellerApi

**TODO: Add description**

* TL;DR: start
* Configuration
* Tests
  * Unit
  * LUX
  * Dialyzer
* Concept
  * Procgen
  * HTTP
  * Monitoring


PROBLEMS

- account depends on transactions (to calculate balance/ledger), thats why we cannot generate account without transactions
- cache should be implemented since procgen might be slow (see above)
- transactions are not fully proc-generated, thus the adjustments needed (date and balances)
- from_string functions should be refactored (lots of shared code)
- token might be optimized to to generate all accounts at once (be lazy)


PLAN

- Cachex
- Logs
- HTTP API (cowboy REST FSM)
- Teller specifics (headers etc), off-switch
- Monitoring
- dialyzer