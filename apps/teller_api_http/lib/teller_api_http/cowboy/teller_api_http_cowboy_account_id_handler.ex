defmodule TellerApiHttp.Cowboy.AccountIdHandler do
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
        true ->
          :cowboy_req.reply(
            200,
            Common.teller_api_headers(),
            Jason.encode!(body(token_data.accounts[account_id])),
            req
          )

        false ->
          :cowboy_req.reply(
            404,
            Common.teller_api_headers(),
            Jason.encode!(Static.error_not_found()),
            req
          )
      end

    {:stop, req, state}
  end

  defp body(account) do
    account_id = Account.to_string(account)

    %{
      currency: account.currency,
      enrollment_id: account.enrollment_id,
      id: account_id,
      institution: %{
        id: account.institution_id,
        name: account.institution_name
      },
      last_four: account.last_four,
      links: %{
        balances: TAH.link_account_balances(account_id),
        self: TAH.link_account(account_id),
        transactions: TAH.link_account_transactions(account_id)
      },
      name: account.name,
      status: account.status,
      subtype: account.subtype,
      type: account.type
    }
  end
end
