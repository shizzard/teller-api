defmodule TellerApiProcgen.Account do
  defmodule T do
    @type t :: %__MODULE__{}
    @enforce_keys [:id, :token_id, :checksum, :pg_state]
    defstruct [:id, :token_id, :checksum, :pg_state, :trxs] ++
                [:currency, :enrollment_id, :institution_id, :institution_name] ++
                [:last_four, :name, :status, :type, :subtype] ++
                [:balances_available, :balances_ledger] ++
                [:details_account_number, :details_routing_numbers_ach]
  end

  use Bitwise
  alias TellerApiProcgen, as: TAP
  alias TellerApiProcgen.Transaction, as: Transaction
  alias TellerApiProcgen.Base36, as: Base36
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Cfg, as: Cfg
  @prefix "acc_"
  @prefix_enrollment "enr_"

  @f_currency "USD"
  @f_status "open"
  @f_type "credit"
  @f_subtype "credit_card"

  @spec new(id :: pos_integer(), token_id :: pos_integer(), cfg :: Cfg.t()) :: T.t()
  def new(id, token_id, %Cfg{} = cfg)
      when is_integer(id) and is_integer(token_id) do
    pg_state = TAP.init_state(token_id, id, 0)
    {pg_state, enr_id} = TAP.integer(pg_state, 1, (1 <<< cfg.accounts_enrollment_id_base) - 1)
    {pg_state, institution_name} = TAP.element(pg_state, Static.institutions())
    {pg_state, institution_id} = {pg_state, institution_name}
    {pg_state, last_four} = TAP.integer(pg_state, 9999)

    predicted_transactions_sum =
      ((cfg.trxs_amount_min + cfg.trxs_amount_max) / 2 * cfg.trxs_per_day * cfg.days_per_account)
      |> trunc()

    {pg_state, routing_numbers_ach} =
      TAP.integer(pg_state, 1, (1 <<< cfg.accounts_routing_numbers_ach) - 1)

    {pg_state, balances_available} =
      TAP.integer(pg_state, predicted_transactions_sum * 2, predicted_transactions_sum * 3)

    generate_transactions(
      %T{
        id: id,
        token_id: token_id,
        checksum: checksum(id, cfg.secret_key),
        pg_state: pg_state,
        currency: @f_currency,
        enrollment_id:
          @prefix_enrollment <>
            Base36.encode((enr_id <<< Static.hash_base()) + checksum(enr_id, cfg.secret_key)),
        institution_id: institution_id,
        institution_name: institution_name,
        last_four: last_four |> Integer.to_string() |> String.pad_leading(4, "0"),
        name: "#{institution_name} Account",
        status: @f_status,
        type: @f_type,
        subtype: @f_subtype,
        balances_available: Decimal.new(balances_available),
        balances_ledger: Decimal.new(balances_available),
        details_account_number: id,
        details_routing_numbers_ach: routing_numbers_ach
      },
      cfg
    )
  end

  @spec from_string(str :: String.t(), token_id :: pos_integer(), cfg :: Cfg.t()) ::
          {:ok, T.t()}
          | {:error, :invalid_format}
          | {:error, :invalid_base36}
          | {:error, :invalid_checksum}
  def from_string(@prefix <> str, token_id, %Cfg{secret_key: secret} = cfg) do
    case Base36.decode(str) do
      :error ->
        {:error, :invalid_base36}

      {:ok, value} ->
        id = div(value, 1 <<< Static.hash_base())
        checksum = rem(value, 1 <<< Static.hash_base())

        if(checksum(id, secret) == checksum) do
          {:ok, new(id, token_id, cfg)}
        else
          {:error, :invalid_checksum}
        end
    end
  end

  def from_string(_, _, _), do: {:error, :invalid_format}

  @spec to_string(t :: T.t()) :: String.t()
  def to_string(%T{id: id, checksum: checksum}) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum)
  end

  @spec to_string(id :: pos_integer(), cfg :: Cfg.t()) :: String.t()
  def to_string(id, cfg) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum(id, cfg.secret_key))
  end

  defp generate_transactions(t, cfg) do
    today = Date.utc_today() |> Date.to_gregorian_days()

    {_pg_state, balances_available_adjusted, balances_ledger_adjusted, trxs} =
      Enum.reduce(
        (today - cfg.days_per_account + 1)..today,
        {t.pg_state, t.balances_available, t.balances_ledger, []},
        fn day, {pg_state_, balances_available_, balances_ledger_, acc} ->
          {pg_state_, trxs_n} = TellerApiProcgen.integer(pg_state_, 1, cfg.trxs_per_day)
          pg_state_day = TellerApiProcgen.init_state(t.token_id, t.id, day)
          {_pg_state_day, trxs} = generate_transactions_day(day, trxs_n, pg_state_day, t, cfg)

          {trxs, balances_available_, balances_ledger_} =
            generate_transactions_adjust_balances(trxs, balances_available_, balances_ledger_)

          {pg_state_, balances_available_, balances_ledger_, [trxs | acc]}
        end
      )

    %T{
      t
      | balances_available: balances_available_adjusted,
        balances_ledger: balances_ledger_adjusted,
        trxs: List.flatten(trxs)
    }
  end

  defp generate_transactions_day(day, trxs_n, pg_state, t, cfg) do
    Enum.reduce(
      1..trxs_n,
      {pg_state, []},
      fn _trx_n, {pg_state_, acc} ->
        {pg_state_, trx_id} = TellerApiProcgen.integer(pg_state_, 1, (1 <<< cfg.trxs_id_base) - 1)

        trx =
          Transaction.new(trx_id, t.token_id, t.id, cfg)
          |> Transaction.adjust_date(day)

        {pg_state_, [trx | acc]}
      end
    )
  end

  defp generate_transactions_adjust_balances(trxs, balance, ledger) do
    {balance, ledger, trxs} =
      Enum.reduce(Enum.reverse(trxs), {balance, ledger, []}, fn trx, {balance_, ledger_, acc} ->
        {trx, balance_, ledger_} = Transaction.adjust_running_balance(trx, balance_, ledger_)
        {balance_, ledger_, [trx | acc]}
      end)

    {trxs, balance, ledger}
  end

  defp checksum(id, secret), do: Static.hash({id, secret})
end
