# TellerApi application description

Application consists of two elixir applications: `TellerApiProcgen` and `TellerApiHttp`.

## `TellerApiProcgen`

This application is responsible for all procedural magic.

Core idea is to use stateful Erlang' `rand` RNG functions. Since we can encode anything we want inside token, we can use that information to generate RNG state. Code for procedural generation of data bits is located in [TellerApiProcgen](/apps/teller_api_procgen/lib/teller_api_procgen.ex) module.

There are three main datastructure generation modules: [`TellerApiProcgen.Token`](/apps/teller_api_procgen/lib/teller_api_procgen_token.ex), [`TellerApiProcgen.Account`](/apps/teller_api_procgen/lib/teller_api_procgen_account.ex) and [`TellerApiProcgen.Transaction`](/apps/teller_api_procgen/lib/teller_api_procgen_transaction.ex). In fact, only one of those is used directly: [`TellerApiProcgen.Token`](/apps/teller_api_procgen/lib/teller_api_procgen_token.ex). Everything else is being generated automatically upon the call.

String ids for all entities are generated using application secret key. Changing this key will regenerate all ids, keeping data the same (assuming you have the same token id).

Overall approach for procedural generation is the following:

- Generators are purely functional. This means that no generator function has a side-effect. This also means that configuration change will have immediate effect, assuming cache cleanup.
- Generators are configurable: [`TellerApiProcgen.Account.T`](/apps/teller_api_procgen/lib/teller_api_procgen_account.ex) and [`TellerApiProcgen.Transaction.T`](/apps/teller_api_procgen/lib/teller_api_procgen_transaction.ex) struct fields are configured with application [configuration](/doc/configuration.md).
- Most of the fields have uniform distribution; You may set the bit-width of numeric fields, changing the effective max value and effective values intervals.
- Some fields, like [`TellerApiProcgen.Transaction.T.status`](/apps/teller_api_procgen/lib/teller_api_procgen_transaction.ex) have a configurable chance to be set to either of two possible values.

According to the rules above, you may imagine some of possible pitfalls. For example, there is a chance to get two transactions with the same id; two accounts with the same id. Erlang `rand` RNG algorithm `exsss` has period of `2^116-1`, so such a coincidence is unlikely, but there are two possible ways to reduce the chance of collision: set wider bit-width for ids and use another algorithm (`exs1024s` has a period of `2^1024-1`).

In any way, there will be collisions in transaction ids and account  ids between tokens, I don't think this one can be avoided.

Probably, I would make generator lazy if I had more time to work on this project. It is impossible to generate [`TellerApiProcgen.Account`](/apps/teller_api_procgen/lib/teller_api_procgen_account.ex) in full without generating all of transactions, since we need transaction amounts; however, accounts are independent and may be generated only when needed.

In any way, every single [`TellerApiProcgen.Token.T`](/apps/teller_api_procgen/lib/teller_api_procgen_token.ex) struct is cached (see below); since we can expect a series of calls for one token in production-like environment, I expect cache hit to be fairly high.

Dig in the [unit test modules](/apps/teller_api_procgen/test/) to see how you call structs generation manually.

## `TellerApiHttp`

This application is responsible for mocking real Teller API.

Since it was not stated mandatory to use Phoenix Framework, I decided to go with [Cowboy REST FSM](https://ninenines.eu/docs/en/cowboy/2.9/guide/rest_principles/). It is fairly simple and can easily be tuned to mock a set of GET handlers.

I didn't bother too much about tuning Cowboy for production-like environment since the application itself is not ready to be deployed to the battle server, thus the default listeners configuration. Cowboy server is very well documented, so it will not be too difficult to prepare it to run in production.

Resource handlers are located in [cowboy](/apps/teller_api_http/lib/teller_api_http/cowboy/) directory, one module per handler. Modules are fairly simple. Common functions are located in [`TellerApiHttp.Cowboy.Common`](/apps/teller_api_http/lib/teller_api_http/cowboy/teller_api_http_cowboy_common.ex) module.

Some of Teller API response headers are also mocked. You can also find those in [`TellerApiHttp.Cowboy.Common`](/apps/teller_api_http/lib/teller_api_http/cowboy/teller_api_http_cowboy_common.ex) module.

`TellerApiHttp` application [configuration](/doc/configuration.md) is self-describing (variables are prefixed with `TELLER_API_HTTP_`).

## Logging

Loggers calls are very limited; Most of the work is done in `TellerApiProcgen` application, so there are really nothing serious to be logged. I did try to do something like very-very basic access log: request and response are logged along with some very-very basic metainformation. Of course, for production environment access log should be reimplemented to match standards: with this approach you can get all standard access log tooling software benefits for free.

## Caching

[`Cachex`](https://hexdocs.pm/cachex/Cachex.html) is used to provide a thin caching layer for the application.

Cache is [configured](/doc/configuration.md) with a pair of environment variables: cache size and cache lifetime (prefixed with `TELLER_API_HTTP_CACHE_`). Cache size is described in [`TellerApiProcgen.Token.T`](/apps/teller_api_procgen/lib/teller_api_procgen_token.ex) structs; by default it will store data for a hundred of tokens. Cache lifetime is described in seconds.

Since new transactions will not be generated until new calendar day, it may be a perfect solution to set every single cache entry expiration date to the start of the next day. To prepare application for production it is a mandatory.
