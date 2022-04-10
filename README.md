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
- cache was implemented since procgen might be slow (see above)
- cache entries expiration should be set to the end of the day, since the data is static
- transactions are not fully proc-generated, thus the adjustments needed (date and balances)
- from_string functions should be refactored (lots of shared code)
- token might be optimized to to generate all accounts at once (be lazy)
- logging is not production-ready
- cowboy listeners should be configured properly for production environments
- LUX tests assume you have `http` client installed
- Probably LUX is not the best tool to test http calls; I would rather use pytest or something similar
- cowboy does not send charset in the content-type header
- 404 errors should be implemented with `resource_exists` cowboy handler, but it is much easier to go straight to the handler because of the data nature (procgen)
- account resources (details, balances, etc.) are a mostly a boilerplate
- get parameters are validated in a very simple way. In real application there sould be generalized validator
- when getting a list of transactions from api.teller.io with a big count parameter, it actually returns that amount


PLAN

- Documentation!
- Monitoring
- dialyzer