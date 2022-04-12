defmodule TellerApiHttp.Application do
  use Application
  import Cachex.Spec
  alias TellerApiProcgen.Token, as: Token
  alias TellerApiProcgen.Static, as: Static

  @impl true
  def start(_type, _args) do
    children = [cachex(), cowboy(), metrics()]
    opts = [strategy: :one_for_one, name: TellerApiHttp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cachex() do
    cache_limit = Application.get_env(:teller_api_http, :cache_limit)
    cache_lifetime_sec = Application.get_env(:teller_api_http, :cache_lifetime_sec)

    {Cachex,
     name: TellerApiHttp.token_cache(),
     fallback:
       fallback(
         default: fn key ->
           case Token.from_string(key, Static.config()) do
             {:ok, data} -> data
             {:error, reason} -> reason
           end
         end
       ),
     limit: limit(size: cache_limit, policy: Cachex.Policy.LRW, reclaim: 0.2),
     expiration:
       expiration(
         default: cache_lifetime_sec * 1000,
         interval: cache_lifetime_sec * 1000,
         lazy: false
       ),
     stats: true}
  end

  defp cowboy(), do: %{id: :cowboy_listener, start: {__MODULE__, :start_cowboy, []}}

  def start_cowboy() do
    dispatch =
      :cowboy_router.compile([
        {TellerApiHttp.http_host(),
         [
           # {PathMatch, Handler, InitialState}
           # prometheus metrics handler
           {"/metrics/[:registry]", :prometheus_cowboy2_handler, []},
           # application handlers
           {"/", TellerApiHttp.Cowboy.RootHandler, %{}},
           {"/accounts", TellerApiHttp.Cowboy.AccountsHandler, %{}},
           {"/accounts/:account_id", TellerApiHttp.Cowboy.AccountIdHandler, %{}},
           {"/accounts/:account_id/details", TellerApiHttp.Cowboy.AccountDetailsHandler, %{}},
           {"/accounts/:account_id/balances", TellerApiHttp.Cowboy.AccountBalancesHandler, %{}},
           {"/accounts/:account_id/transactions", TellerApiHttp.Cowboy.AccountTransactionsHandler,
            %{}},
           {"/accounts/:account_id/transactions/:transaction_id",
            TellerApiHttp.Cowboy.AccountTransactionIdHandler, %{}},
           {:_, TellerApiHttp.Cowboy.DefaultHandler, %{}}
         ]},
        {:_, [{:_, TellerHttpApi.Cowboy.DefaultHandler, %{}}]}
      ])

    :cowboy.start_clear(
      :teller_api_http_cowboy,
      [{:port, TellerApiHttp.http_port()}],
      %{
        env: %{
          dispatch: dispatch,
          metrics_callback: &:prometheus_cowboy2_instrumenter.observe/1,
          stream_handlers: [:cowboy_metrics_h]
        }
      }
    )
  end

  def metrics() do
    TellerApiHttp.Metrics.declare_metrics()
    {TellerApiHttp.Metrics, []}
  end
end
