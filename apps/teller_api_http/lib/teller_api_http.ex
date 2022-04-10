defmodule TellerApiHttp do
  @spec token_cache() :: atom()
  def token_cache(), do: :teller_api_token_cache

  @spec token_cache_stats() :: map()
  def token_cache_stats(), do: Cachex.stats(token_cache())

  @spec token_fetch(token :: String.t()) :: {:ok, Token.T.t()}
  def token_fetch(token) do
    {_, ret} = Cachex.fetch(token_cache(), token)
    ret
  end

  @spec link_accounts() :: String.t()
  def link_accounts(),
    do: "#{http_proto()}://#{http_host()}:#{http_port()}/accounts"

  @spec link_account(account_id :: String.t()) :: String.t()
  def link_account(account_id),
    do: "#{http_proto()}://#{http_host()}:#{http_port()}/accounts/#{account_id}"

  @spec link_account_details(account_id :: String.t()) :: String.t()
  def link_account_details(account_id),
    do: "#{http_proto()}://#{http_host()}:#{http_port()}/accounts/#{account_id}/details"

  @spec link_account_balances(account_id :: String.t()) :: String.t()
  def link_account_balances(account_id),
    do: "#{http_proto()}://#{http_host()}:#{http_port()}/accounts/#{account_id}/balances"

  @spec link_account_transactions(account_id :: String.t()) :: String.t()
  def link_account_transactions(account_id),
    do: "#{http_proto()}://#{http_host()}:#{http_port()}/accounts/#{account_id}/transactions"

  @spec link_account_transaction(account_id :: String.t(), transaction_id :: String.t()) ::
          String.t()
  def link_account_transaction(account_id, transaction_id),
    do:
      "#{http_proto()}://#{http_host()}:#{http_port()}/accounts/#{account_id}/transactions/#{transaction_id}"

  @spec http_proto() :: String.t()
  def http_proto(), do: Application.get_env(:teller_api_http, :proto)

  @spec http_host() :: String.t()
  def http_host(), do: Application.get_env(:teller_api_http, :host)

  @spec http_port() :: pos_integer()
  def http_port(), do: Application.get_env(:teller_api_http, :port)
end
