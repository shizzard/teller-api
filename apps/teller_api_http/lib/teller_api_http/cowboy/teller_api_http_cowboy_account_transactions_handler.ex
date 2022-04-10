defmodule TellerApiHttp.Cowboy.AccountTransactionsHandler do
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

    req =
      case Map.has_key?(token_data.accounts, account_id) do
        true ->
          to_json_transactions(token_data.accounts[account_id], req, state)

        false ->
          Common.respond(404, Static.error_not_found(), req, state)
      end

    {:stop, req, state}
  end

  defp to_json_transactions(account, req, state) do
    case get_pagination_params(req) do
      {:ok, {count, from_id}} ->
        to_json_transactions_paginated(count, from_id, account.trxs, req, state)

      {:error, {:invalid_param, message}} ->
        Common.respond(400, Static.error_bad_request(message), req, state)
    end
  end

  defp to_json_transactions_paginated(count, nil, trxs, req, state),
    do: to_json_transactions_paginated_cut_right(count, trxs, req, state)

  defp to_json_transactions_paginated(count, from_id, trxs, req, state),
    do: to_json_transactions_paginated_cut_left(count, from_id, trxs, req, state)

  defp to_json_transactions_paginated_cut_left(_, from_id, [], req, state),
    do:
      Common.respond(
        400,
        Static.error_bad_request("The transaction \"#{from_id}\" in \"from_id\" was not found."),
        req,
        state
      )

  defp to_json_transactions_paginated_cut_left(count, from_id, [trx | rest], req, state) do
    case {Transaction.to_string(trx), count} do
      {^from_id, nil} ->
        Common.respond(200, body(rest), req, state)

      {^from_id, count} ->
        to_json_transactions_paginated_cut_right(count, rest, req, state)

      _ ->
        to_json_transactions_paginated_cut_left(count, from_id, rest, req, state)
    end
  end

  defp to_json_transactions_paginated_cut_right(nil, trxs, req, state),
    do: Common.respond(200, body(trxs), req, state)

  defp to_json_transactions_paginated_cut_right(count, trxs, req, state),
    do: Common.respond(200, trxs |> Enum.slice(0..(count - 1)) |> body(), req, state)

  defp body(trxs), do: Enum.reduce(trxs, [], &body_encode_transaction/2) |> Enum.reverse()

  defp body_encode_transaction(trx, acc) do
    account_id = Account.to_string(trx.account_id, TellerApiProcgen.Static.config())
    transaction_id = Transaction.to_string(trx)

    [
      %{
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
      | acc
    ]
  end

  defp get_pagination_params(req) do
    get_pagination_params_qs(:cowboy_req.parse_qs(req), {nil, nil})
  end

  defp get_pagination_params_qs([], params), do: {:ok, params}

  defp get_pagination_params_qs([{"count", v} | rest], {_, from_id}) do
    try do
      v = String.to_integer(v)

      case v > 0 do
        true ->
          get_pagination_params_qs(rest, {v, from_id})

        false ->
          {:error,
           {:invalid_param, "The \"count\" param must be a positive integer. You sent \"#{v}\"."}}
      end
    rescue
      _ ->
        {:error, {:invalid_param, "The \"count\" param must be an integer. You sent \"#{v}\"."}}
    end
  end

  defp get_pagination_params_qs([{"from_id", v} | rest], {count, _}),
    do: get_pagination_params_qs(rest, {count, v})
end
