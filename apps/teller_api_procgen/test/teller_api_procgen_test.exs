defmodule TellerApiProcgenTest do
  use ExUnit.Case, async: true
  doctest TellerApiProcgen

  alias TellerApiProcgen, as: TAP

  ## Probably the best way to test such APIs is property-based testing.
  ## I didn't try to use PropEr/QuickCheck in Elixir, but it is possible.
  ## However, it seems to be quite an overengineering here.

  def pg_state() do
    # Using ExUnit seed to ensure we will get the same results
    # when running test suite with the same seed
    seed = Keyword.fetch!(ExUnit.configuration(), :seed)
    TAP.init_state(seed, seed + 1, seed + 2)
  end

  ## NB: this case is not tested
  def pg_state(algo) do
    seed = Keyword.fetch!(ExUnit.configuration(), :seed)
    TAP.init_state(algo, seed, seed + 1, seed + 2)
  end

  test "random integer errors" do
    catch_error(TAP.integer(pg_state(), -1))
    catch_error(TAP.integer(pg_state(), 0))
  end

  test "random integer bounds upper" do
    {_, 1} = TAP.integer(pg_state(), 1)
    {_, x} = TAP.integer(pg_state(), 10)
    assert x >= 1
    assert x <= 10
  end

  test "random integer bounds lower/upper" do
    {_, x} = TAP.integer(pg_state(), 10, 20)
    assert x >= 10
    assert x <= 20
  end

  test "random integer repeatable" do
    {_, x} = TAP.integer(pg_state(), 10, 20)
    {_, ^x} = TAP.integer(pg_state(), 10, 20)
  end

  test "random boolean errors" do
    catch_error(TAP.boolean(pg_state(), 1))
    catch_error(TAP.boolean(pg_state(), -0.2))
    catch_error(TAP.boolean(pg_state(), 1.2))
  end

  test "random boolean" do
    {_, x} = TAP.boolean(pg_state(), 0.5)
    assert x || !x
  end

  test "random boolean repeatable" do
    {_, x} = TAP.boolean(pg_state(), 0.5)
    {_, ^x} = TAP.boolean(pg_state(), 0.5)
  end

  test "random boolean predictable" do
    {_, x} = TAP.boolean(pg_state(), 1.0)
    assert x
  end

  test "random decimal errors" do
    catch_error(TAP.decimal(pg_state(), 10, 10, 1))
    catch_error(TAP.decimal(pg_state(), 10, 20, 0))
    catch_error(TAP.decimal(pg_state(), 10, 20, 11))
  end

  test "random decimal bounds lower/upper" do
    {_, x} = TAP.decimal(pg_state(), 10, 20, 1)
    assert Decimal.compare(x, Decimal.new(9)) == :gt
    assert Decimal.compare(x, Decimal.new(21)) == :lt
  end

  test "random decimal repeatable" do
    {_, x} = TAP.decimal(pg_state(), 10, 20, 1)
    {_, ^x} = TAP.decimal(pg_state(), 10, 20, 1)
  end

  test "random element errors" do
    catch_error(TAP.element(pg_state(), []))
  end

  test "random element" do
    {_, 1} = TAP.element(pg_state(), [1])
    l = Enum.to_list(1..10)
    {_, x} = TAP.element(pg_state(), l)
    assert Enum.member?(l, x)
  end

  test "random element repeatable" do
    l = Enum.to_list(1..10)
    {_, x} = TAP.element(pg_state(), l)
    {_, ^x} = TAP.element(pg_state(), l)
  end

  test "random pass mutates state" do
    s = pg_state()
    catch_error({^s, _} = TAP.integer(pg_state(), 10))
    catch_error({^s, _} = TAP.integer(pg_state(), 10, 20))
    catch_error({^s, _} = TAP.decimal(pg_state(), 10, 20, 1))
    catch_error({^s, _} = TAP.element(pg_state(), Enum.to_list(1..10)))
  end

  test "random map" do
    {_, %{a: 1}} =
      TAP.map(pg_state(), %{
        a: fn s -> TAP.integer(s, 1) end
      })

    {_, %{a: _, b: _, c: _}} =
      TAP.map(pg_state(), %{
        a: fn s -> TAP.integer(s, 10, 20) end,
        b: fn s -> TAP.integer(s, 10, 20) end,
        c: fn s -> TAP.integer(s, 10, 20) end
      })
  end

  test "random nested map" do
    ## `mix format` goes crazy here
    {_, %{a: %{b: 1}}} =
      TAP.map(pg_state(), %{
        a: fn s0 ->
          TAP.map(s0, %{
            b: fn s1 -> TAP.element(s1, [1]) end
          })
        end
      })
  end
end
