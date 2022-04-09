defmodule TellerApiProcgen.Token do
  defmodule T do
    @type t :: %__MODULE__{}
    @enforce_keys [:id, :checksum, :pg_state, :accounts_n]
    defstruct [:id, :checksum, :pg_state, :accounts_n, :accounts]
  end

  use Bitwise
  alias TellerApiProcgen, as: TAP
  alias TellerApiProcgen.Cfg, as: Cfg
  alias TellerApiProcgen.Base36, as: Base36
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Account, as: Account
  @prefix "test_"

  @spec new(id :: pos_integer(), cfg :: Cfg.t()) :: T.t()
  def new(id, %Cfg{} = cfg) when is_integer(id) do
    pg_state = TAP.init_state(id, 0, 0)
    {_pg_state_mut, accounts_n} = TAP.integer(pg_state, 1, cfg.accounts_max)

    generate_accounts(
      %T{
        id: id,
        checksum: checksum(id, cfg.secret_key),
        pg_state: pg_state,
        accounts_n: accounts_n
      },
      cfg
    )
  end

  @spec from_string(str :: String.t(), cfg :: Cfg.t()) ::
          {:ok, T.t()}
          | {:error, :invalid_format}
          | {:error, :invalid_base36}
          | {:error, :invalid_checksum}
  def from_string(@prefix <> str, %Cfg{secret_key: secret} = cfg) do
    case Base36.decode(str) do
      :error ->
        {:error, :invalid_base36}

      {:ok, value} ->
        id = div(value, 1 <<< Static.hash_base())
        checksum = rem(value, 1 <<< Static.hash_base())

        if(checksum(id, secret) == checksum) do
          {:ok, new(id, cfg)}
        else
          {:error, :invalid_checksum}
        end
    end
  end

  def from_string(_, _), do: {:error, :invalid_format}

  @spec to_string(t :: T.t()) :: String.t()
  def to_string(%T{id: id, checksum: checksum}) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum)
  end

  @spec to_string(id :: pos_integer(), cfg :: Cfg.t()) :: String.t()
  def to_string(id, cfg) do
    @prefix <> Base36.encode((id <<< Static.hash_base()) + checksum(id, cfg.secret_key))
  end

  defp generate_accounts(t, cfg) do
    accounts =
      Enum.reduce(1..t.accounts_n, {t.pg_state, []}, fn _n, {pg_state_, acc} ->
        {pg_state_, account_id} = TAP.integer(pg_state_, 1, (1 <<< cfg.accounts_id_base) - 1)

        account = Account.new(account_id, t.id, cfg)
        {pg_state_, [{Account.to_string(account), account} | acc]}
      end)
      |> elem(1)
      |> Map.new()

    %T{t | accounts: accounts}
  end

  defp checksum(id, secret), do: Static.hash({id, secret})
end
