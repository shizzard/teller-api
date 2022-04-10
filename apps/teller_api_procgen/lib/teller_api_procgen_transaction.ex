defmodule TellerApiProcgen.Transaction do
  defmodule T do
    @type t :: %__MODULE__{}
    @enforce_keys [:id, :token_id, :account_id, :checksum, :pg_state]
    defstruct [:id, :token_id, :account_id, :checksum, :pg_state] ++
                [:details_category, :details_counterparty_name, :details_counterparty_type] ++
                [:details_processing_status, :amount, :date, :running_balance, :status, :type]
  end

  use Bitwise
  alias TellerApiProcgen, as: TAP
  alias TellerApiProcgen.Base36, as: Base36
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Cfg, as: Cfg
  @prefix "txn_"

  @f_details_counterparty_type "organization"
  @f_details_processing_status_complete "complete"
  @f_details_processing_status_pending "pending"
  @f_status_posted "posted"
  @f_status_pending "pending"
  @f_type "card_payment"

  @spec new(
          id :: pos_integer(),
          token_id :: pos_integer(),
          account_id :: pos_integer(),
          cfg :: Cfg.t()
        ) :: T.t()
  def new(id, token_id, account_id, %Cfg{} = cfg)
      when is_integer(id) and is_integer(token_id) and is_integer(account_id) do
    pg_state = TAP.init_state(token_id, account_id, id)
    {pg_state, merchant} = TAP.element(pg_state, Static.merchants())
    {pg_state, merchant_category} = TAP.element(pg_state, Static.merchant_categories())
    {pg_state, amount} = TAP.decimal(pg_state, cfg.trxs_amount_min, cfg.trxs_amount_max, 2)

    {pg_state, processing_status} =
      case TAP.boolean(pg_state, cfg.trxs_processing_status_complete_chance) do
        {pg_state, true} -> {pg_state, @f_details_processing_status_complete}
        {pg_state, false} -> {pg_state, @f_details_processing_status_pending}
      end

    {pg_state, status} =
      case {processing_status, TAP.boolean(pg_state, cfg.trxs_status_posted_chance)} do
        {@f_details_processing_status_complete, {pg_state, true}} -> {pg_state, @f_status_posted}
        {_, {pg_state, _}} -> {pg_state, @f_status_pending}
      end

    %T{
      id: id,
      token_id: token_id,
      account_id: account_id,
      checksum: checksum(id, cfg.secret_key),
      pg_state: pg_state,
      details_category: merchant_category,
      details_counterparty_name: merchant,
      details_counterparty_type: @f_details_counterparty_type,
      details_processing_status: processing_status,
      amount: amount,
      status: status,
      type: @f_type
    }
  end

  @spec from_string(
          str :: String.t(),
          token_id :: pos_integer(),
          account_id :: pos_integer(),
          cfg :: Cfg.t()
        ) ::
          {:ok, T.t()}
          | {:error, :invalid_format}
          | {:error, :invalid_base36}
          | {:error, :invalid_checksum}
  def from_string(@prefix <> str, token_id, account_id, %Cfg{secret_key: secret} = cfg) do
    case Base36.decode(str) do
      :error ->
        {:error, :invalid_base36}

      {:ok, value} ->
        id = div(value, 1 <<< Static.hash_base())
        checksum = rem(value, 1 <<< Static.hash_base())

        if(checksum(id, secret) == checksum) do
          {:ok, new(id, token_id, account_id, cfg)}
        else
          {:error, :invalid_checksum}
        end
    end
  end

  def from_string(_, _, _, _), do: {:error, :invalid_format}

  @spec to_string(t :: T.t()) :: String.t()
  def to_string(%T{id: id, checksum: checksum}) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum)
  end

  @spec to_string(id :: pos_integer(), cfg :: Cfg.t()) :: String.t()
  def to_string(id, cfg) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum(id, cfg.secret_key))
  end

  @spec adjust_date(t :: T.t(), day :: pos_integer()) :: T.t()
  def adjust_date(t, day), do: %T{t | date: Date.from_gregorian_days(day) |> Date.to_iso8601()}

  @spec adjust_running_balance(t :: T.t(), balance_in :: Decimal.t(), ledger_in :: Decimal.t()) ::
          {t :: T.t(), balance_out :: Decimal.t(), ledger_out :: Decimal.t()}
  def adjust_running_balance(t, balance_in, ledger_in) do
    {balance_out, ledger_out, running_balance} =
      case t.status do
        @f_status_posted ->
          {Decimal.sub(balance_in, t.amount), Decimal.sub(ledger_in, t.amount),
           Decimal.sub(balance_in, t.amount)}

        @f_status_pending ->
          {Decimal.sub(balance_in, t.amount), ledger_in, nil}
      end

    {%T{t | running_balance: running_balance}, balance_out, ledger_out}
  end

  defp checksum(id, secret), do: Static.hash({id, secret})
end
