**Since Teller did not bother to give even formal feedback on the results of the test task, on which I spent several hours, I decided to opensource the project.**

# TellerApi application

[Configuration](/doc/configuration.md)

[Application description](/doc/application.md)

[Tests](/doc/tests.md)

[Monitoring](/doc/monitoring.md)

[Known issues](/doc/issues.md)

## TL;DR: start

Application expects the following software to be installed:

- Erlang/OTP (tested with 24.0.4)
- Elixir (test with 1.13.3)

To be able to run tests:

- Python 3.10+
- Python Requests library

To build the release, run `make`:

```
  > make
  /Users/shizz/.kiex/elixirs/elixir-1.13.3/bin/mix deps.get
  Resolving Hex dependencies...
  Dependency resolution completed:
  ... deps information ...
  /Users/shizz/.kiex/elixirs/elixir-1.13.3/bin/mix compile
  ... compilation process ...
  /Users/shizz/.kiex/elixirs/elixir-1.13.3/bin/mix release --overwrite
  ... build release process ...

  Release created at _build/dev/rel/teller_api!
  ...
```

To run the application, execute `make run`:

```
  > make run
  /Users/shizz/.kiex/elixirs/elixir-1.13.3/bin/mix compile
  /Users/shizz/.kiex/elixirs/elixir-1.13.3/bin/mix release --overwrite
  ... build release process ...

  --   Application ENV  --
  ... application configuration ...
  --   Application ENV  --
  /Users/shizz/code/teller_api/_build/dev/rel/teller_api/bin/teller_api start_iex
  Erlang/OTP 24 [erts-12.0.3] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [jit]

  Interactive Elixir (1.13.3) - press Ctrl+C to exit (type h() ENTER for help)
  iex(teller_api@LT1-AL-013)1>
```

To generate a token to play with API, you can run elixir snippet:

```
iex(teller_api@LT1-AL-013)1> TellerApiProcgen.Token.new(100, TellerApiProcgen.Static.config()) |> TellerApiProcgen.Token.to_string
"test_5j8wmb4o"
```

Here `100` is token id used to generate related data.

For further information please refer to the links at the top of the page.
