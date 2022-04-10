# TellerApi application tests

To run project tests ensure application is not running and execute `make check` command:

```
  > make check
  =====  FORMAT RUN  =====
  ...
  =====  FORMAT END  =====
  ===== DIALYZER RUN =====
  ...
  ===== DIALYZER END =====
  =====   EUNIT RUN  =====
  ...
  =====   EUNIT END  =====
  =====    LUX RUN   =====
  ...
  =====    LUX END   =====
```

## Code formatting

Run separately: `check-format`.

Check if code is formatted with standard `mix format` tool. I didn't try to tune the tool configuration. Probably that's why sometimes it goes crazy when formatting the code.

In any way, it is better to have code ugly but standard, instead of having it beautiful in a hundred ways.

## Dialyzer

Dialyzer runs are omitted; In such a simple project dialyzer doesn't give too much, that's why it was planned with a very small priority. Unfortunately, I didn't have a time to pull it.

## Unit tests

Run separately: `make unit-tests`.

[Unit test modules](/apps/teller_api_procgen/test/) are self-describing. I will not pretend those have perfect test coverage.

All unit tests are using `ExUnit` seed to feed the procedural generation. In this way you can be sure you will have the same generator run with the same seed provided. Seed is random by default.

If I had more time, I would rather go with property-based testing. In my experience, proptests are perfect substitution for unit tests, since you don't need to think about corner-cases, only about system invariants.

## Integration tests

Integration tests are done with [LUX](https://github.com/hawk/lux/blob/master/doc/lux.md). It is a test automation framework with Expect style execution of commands. In my experience it is a very elegant way to test almost anything: I did test lots of different APIs, but I never try to test HTTP RESTful API. For now it seems that it might not be a perfect solution; however, it forces you to write some tooling to operate your API, and tooling, in my opinion, is a cheap way to improve dev team productivity.

I wrote a dirty [Teller API Client](/_tools/teller_client.py). It is not a state of the art, but is does its job. This client performs API requests and outputs the results to be regex-processable. [LUX tests](/test/lux/http/) use this client to perform requests. Tests are written in a separate directories, one per HTTP handler.

Common functions are located in [__common](/test/lux/__common/) directory.

Every single test is starting the server and stopping it in the end. It might not seem an effective approach, but with some extra work it allows you to highly paralellize the test runs, while keeping those isolated; this parallelization actualy might speed up the whole process. This approach also allows you to cheaply test a wide range of application configurations and even several different application builds (probably, not actual problem for Teller though).