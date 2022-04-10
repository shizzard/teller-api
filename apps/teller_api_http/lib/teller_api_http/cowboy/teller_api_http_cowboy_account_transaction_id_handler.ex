defmodule TellerApiHttp.Cowboy.AccountTransactionIdHandler do
  require Logger
  alias TellerApiHttp, as: TAH
  alias TellerApiHttp.Static, as: Static
  alias TellerApiHttp.Cowboy.Common, as: Common
  alias TellerApiHttp.Cowboy.Common.State, as: CommonState
  alias TellerApiProcgen.Account, as: Account
  alias TellerApiProcgen.Transaction, as: Transaction

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)
  def is_authorized(req, state), do: Common.cb_is_authorized(req, state)

  def to_json(req, state) do
    token_data = TAH.token_fetch(CommonState.auth_token(state))
    account_id = :cowboy_req.binding(:account_id, req)
    transaction_id = :cowboy_req.binding(:transaction_id, req)

    req =
      case Map.has_key?(token_data.accounts, account_id) do
        true ->
          to_json_transaction(transaction_id, token_data.accounts[account_id], req, state)

        false ->
          Common.respond(404, Static.error_not_found(), req, state)
      end

    {:stop, req, state}
  end

  defp to_json_transaction(transaction_id, account, req, state) do
    case Enum.find(account.trxs, fn trx ->
           Transaction.to_string(trx) == transaction_id
         end) do
      nil ->
        Common.respond(404, Static.error_not_found(), req, state)

      trx ->
        account_id = Account.to_string(account)

        body = %{
          account_id: account_id,
          amount: trx.amount |> Decimal.to_string(),
          date: trx.date,
          description: trx.details_counterparty_name,
          details: %{
            category: trx.details_category,
            counterparty: %{
              name: trx.details_counterparty_name,
              type: trx.details_counterparty_type
            },
            processing_status: trx.details_processing_status
          },
          id: transaction_id,
          links: %{
            account: TAH.link_account(account_id),
            self: TAH.link_account_transaction(account_id, transaction_id)
          },
          running_balance:
            case trx.running_balance do
              nil -> nil
              balance -> balance |> Decimal.to_string()
            end,
          status: trx.status,
          type: trx.type
        }

        Common.respond(200, body, req, state)
    end
  end
end
