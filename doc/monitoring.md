# TellerApi applciation monitoring

Monitoring is based on [Prometheus](https://github.com/deadtrickster/prometheus.erl) library. There are three groups of metrics.

All metrics can be read with calling `/metrics` URL and can be easily imported in a tool like Grafana.

## Cowboy metrics

Cowboy metrics are exported with [Prometheus-Cowboy](https://github.com/deadtrickster/prometheus-cowboy) library.

```
  > http localhost:8080/metrics | grep cowboy
  # TYPE cowboy_errors_total counter
  ...
```

## Erlang VM metrics

Erlang VM metrics are handled by [Prometheus](https://github.com/deadtrickster/prometheus.erl) library itself.

```
  > http localhost:8080/metrics | grep erlang
  # TYPE erlang_vm_dist_recv_bytes gauge
  ...
```

## Application metrics

There are two metrics that are exported: cache calls and cache rates (hit and miss). You can find the reporter in [TellerApiHttp.Metrics](/apps/teller_api_http/lib/teller_api_http/metrics/teller_api_http_metrics.ex) module.

```
  > http localhost:8080/metrics | grep teller
  # TYPE teller_api_cache_rate gauge
  # HELP teller_api_cache_rate Teller API cache rates
  teller_api_cache_rate{type="miss"} 12.5
  teller_api_cache_rate{type="hit"} 87.5
  # TYPE teller_api_cache_calls gauge
  # HELP teller_api_cache_calls Teller API cache calls
  teller_api_cache_calls{type="purge"} 1
  teller_api_cache_calls{type="fetch"} 8
  teller_api_cache_calls{type="stats"} 8
```