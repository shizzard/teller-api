defmodule TellerApiProcgenAccountTest do
  use ExUnit.Case, async: true
  doctest TellerApiProcgen

  alias TellerApiProcgen.Transaction, as: Transaction
  alias TellerApiProcgen.Account, as: Account
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Cfg, as: Cfg

  test "account create" do
    assert %Account.T{} = Account.new(100, 200, Static.config())
  end

  test "accounts differ with different secrets" do
    cfg0 = Static.config()
    cfg1 = %Cfg{cfg0 | secret_key: 1337}
    t0 = Account.new(100, 200, cfg0) |> Account.to_string()
    t1 = Account.new(100, 200, cfg1) |> Account.to_string()
    assert t0 != t1
  end

  test "account balance and ledger diff is correct" do
    account = Account.new(100, 200, Static.config())

    calculated_diff =
      Enum.reduce(account.trxs, Decimal.new(0), fn
        %Transaction.T{status: "pending", amount: amount}, acc ->
          Decimal.add(amount, acc)

        _trx, acc ->
          acc
      end)

    actual_diff = Decimal.sub(account.balances_ledger, account.balances_available)
    assert Decimal.compare(calculated_diff, actual_diff) == :eq
  end

  test "account to_string" do
    assert "acc_" <> _ =
             Account.new(100, 200, Static.config())
             |> Account.to_string()
  end

  test "account from_string" do
    account = Account.new(100, 200, Static.config())

    assert {:ok, account} ==
             account
             |> Account.to_string()
             |> Account.from_string(200, Static.config())
  end

  test "account from_string format error" do
    assert {:error, :invalid_format} = Account.from_string("acc", 200, Static.config())
  end

  test "account from_string base36 error" do
    assert {:error, :invalid_base36} =
             Account.from_string("acc_INVALIDBASE36", 200, Static.config())
  end

  test "account from_string checksum error" do
    assert {:error, :invalid_checksum} =
             Account.from_string("acc_invalidchecksum", 200, Static.config())
  end

  test "account generates new transaction every day" do
    cfg0 = %Cfg{
      Static.config()
      | today_date: Date.from_iso8601!("2022-04-12") |> Date.to_gregorian_days()
    }

    cfg1 = %Cfg{
      Static.config()
      | today_date: Date.from_iso8601!("2022-04-13") |> Date.to_gregorian_days()
    }

    t0 = Account.new(100, 200, cfg0)
    t1 = Account.new(100, 200, cfg1)
    assert Enum.slice(t0.trxs, 0..0) != Enum.slice(t1.trxs, 0..0)
  end
end
