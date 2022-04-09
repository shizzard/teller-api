defmodule TellerApiProcgenTransactionTest do
  use ExUnit.Case, async: true
  doctest TellerApiProcgen

  alias TellerApiProcgen.Transaction, as: Transaction
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Cfg, as: Cfg

  test "trx create" do
    assert %Transaction.T{} = Transaction.new(100, 200, 300, Static.config())
  end

  test "trxs differ with different secrets" do
    cfg0 = Static.config()
    cfg1 = %Cfg{cfg0 | secret_key: 1337}
    t0 = Transaction.new(100, 200, 300, cfg0) |> Transaction.to_string()
    t1 = Transaction.new(100, 200, 300, cfg1) |> Transaction.to_string()
    assert t0 != t1
  end

  test "trx date adjustable" do
    trx = Transaction.new(100, 200, 300, Static.config())
    assert %Transaction.T{date: "2022-04-09"} = Transaction.adjust_date(trx, 738_619)
  end

  test "trx posted running_balance adjustable" do
    balance_in = Decimal.new(150)
    ledger_in = Decimal.new(100)
    trx = %Transaction.T{Transaction.new(100, 200, 300, Static.config()) | status: "posted"}

    {trx, balance_out, ledger_out} =
      Transaction.adjust_running_balance(trx, balance_in, ledger_in)

    assert Decimal.compare(balance_in, balance_out) == :gt
    assert Decimal.compare(ledger_in, ledger_out) == :gt
    assert trx.running_balance == balance_out
  end

  test "trx pending running_balance adjustable" do
    balance_in = Decimal.new(150)
    ledger_in = Decimal.new(100)
    trx = %Transaction.T{Transaction.new(100, 200, 300, Static.config()) | status: "pending"}

    {trx, balance_out, ledger_out} =
      Transaction.adjust_running_balance(trx, balance_in, ledger_in)

    assert Decimal.compare(balance_in, balance_out) == :gt
    assert Decimal.compare(ledger_in, ledger_out) == :eq
    assert trx.running_balance == nil
  end

  test "trx to_string" do
    assert "txn_" <> _ =
             Transaction.new(100, 200, 300, Static.config())
             |> Transaction.to_string()
  end

  test "trx from_string" do
    trx = Transaction.new(100, 200, 300, Static.config())

    assert {:ok, trx} ==
             trx
             |> Transaction.to_string()
             |> Transaction.from_string(200, 300, Static.config())
  end

  test "trx from_string format error" do
    assert {:error, :invalid_format} = Transaction.from_string("txn", 200, 300, Static.config())
  end

  test "trx from_string base36 error" do
    assert {:error, :invalid_base36} =
             Transaction.from_string("txn_INVALIDBASE36", 200, 300, Static.config())
  end

  test "trx from_string checksum error" do
    assert {:error, :invalid_checksum} =
             Transaction.from_string("txn_invalidchecksum", 200, 300, Static.config())
  end
end
