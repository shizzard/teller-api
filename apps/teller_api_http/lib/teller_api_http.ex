defmodule TellerApiHttp do
  @spec token_cache() :: atom()
  def token_cache(), do: :teller_api_token_cache

  @spec token_cache_stats() :: map()
  def token_cache_stats(), do: Cachex.stats(token_cache())

  @spec token_fetch(token :: String.t()) :: {:ok, Token.T.t()}
  def token_fetch(token) do
    {:ok, ret} = Cachex.fetch(token_cache(), token)
    ret
  end
end
