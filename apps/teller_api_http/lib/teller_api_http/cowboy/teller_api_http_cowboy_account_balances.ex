defmodule TellerApiHttp.Cowboy.AccountBalancesHandler do
  require Logger
  alias TellerApiHttp, as: TAH
  alias TellerApiHttp.Static, as: Static
  alias TellerApiHttp.Cowboy.Common, as: Common
  alias TellerApiHttp.Cowboy.Common.State, as: CommonState
  alias TellerApiProcgen.Account, as: Account

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)
  def is_authorized(req, state), do: Common.cb_is_authorized(req, state)

  def to_json(req, state) do
    token_data = TAH.token_fetch(CommonState.auth_token(state))
    account_id = :cowboy_req.binding(:account_id, req)

    req =
      case Map.has_key?(token_data.accounts, account_id) do
        true -> Common.respond(200, body(token_data.accounts[account_id]), req, state)
        false -> Common.respond(404, Static.error_not_found(), req, state)
      end

    {:stop, req, state}
  end

  defp body(account) do
    account_id = Account.to_string(account)

    %{
      account_id: account_id,
      available: account.balances_available |> Decimal.to_string(),
      ledger: account.balances_ledger |> Decimal.to_string(),
      links: %{
        account: TAH.link_account(account_id),
        self: TAH.link_account_balances(account_id)
      }
    }
  end
end
