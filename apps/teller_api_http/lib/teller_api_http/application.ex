defmodule TellerApiHttp.Application do
  use Application
  import Cachex.Spec
  alias TellerApiProcgen.Token, as: Token
  alias TellerApiProcgen.Static, as: Static

  @impl true
  def start(_type, _args) do
    cache_limit = Application.get_env(:teller_api_http, :cache_limit)
    cache_lifetime_sec = Application.get_env(:teller_api_http, :cache_lifetime_sec)

    children = [
      {Cachex,
       name: TellerApiHttp.token_cache(),
       fallback: fallback(default: fn key -> Token.from_string(key, Static.config()) end),
       limit: limit(size: cache_limit, policy: Cachex.Policy.LRW, reclaim: 0.2),
       expiration:
         expiration(
           default: cache_lifetime_sec * 1000,
           interval: cache_lifetime_sec * 1000,
           lazy: false
         ),
       stats: true}
    ]

    opts = [strategy: :one_for_one, name: TellerApiHttp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
