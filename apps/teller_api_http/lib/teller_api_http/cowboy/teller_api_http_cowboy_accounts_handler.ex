defmodule TellerApiHttp.Cowboy.AccountsHandler do
  require Logger
  alias TellerApiHttp, as: TAH
  alias TellerApiHttp.Cowboy.Common, as: Common
  alias TellerApiHttp.Cowboy.Common.State, as: CommonState

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)
  def is_authorized(req, state), do: Common.cb_is_authorized(req, state)

  def to_json(req, state) do
    token_data = TAH.token_fetch(CommonState.auth_token(state))

    req = Common.respond(200, body(token_data), req, state)

    {:stop, req, state}
  end

  defp body(token_data) do
    Enum.reduce(token_data.accounts, [], &body_encode_account/2)
  end

  defp body_encode_account({account_id, account}, acc) do
    [
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
          details: TAH.link_account_details(account_id),
          self: TAH.link_account(account_id),
          transactions: TAH.link_account_transactions(account_id)
        },
        name: account.name,
        status: account.status,
        subtype: account.subtype,
        type: account.type
      }
      | acc
    ]
  end
end
