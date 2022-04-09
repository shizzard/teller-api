defmodule TellerApiProcgenTokenTest do
  use ExUnit.Case, async: true
  doctest TellerApiProcgen

  alias TellerApiProcgen.Token, as: Token
  alias TellerApiProcgen.Static, as: Static
  alias TellerApiProcgen.Cfg, as: Cfg

  test "token create" do
    assert %Token.T{} = Token.new(100, Static.config())
  end

  test "tokens differ with different secrets" do
    cfg0 = Static.config()
    cfg1 = %Cfg{cfg0 | secret_key: 1337}
    t0 = Token.new(100, cfg0) |> Token.to_string()
    t1 = Token.new(100, cfg1) |> Token.to_string()
    assert t0 != t1
  end

  test "token to_string" do
    assert "test_" <> _ = Token.new(100, Static.config()) |> Token.to_string()
  end

  test "token from_string" do
    token = Token.new(100, Static.config())
    assert {:ok, token} == token |> Token.to_string() |> Token.from_string(Static.config())
  end

  test "token from_string format error" do
    assert {:error, :invalid_format} = Token.from_string("test", Static.config())
  end

  test "token from_string base36 error" do
    assert {:error, :invalid_base36} = Token.from_string("test_INVALIDBASE36", Static.config())
  end

  test "token from_string checksum error" do
    assert {:error, :invalid_checksum} =
             Token.from_string("test_invalidchecksum", Static.config())
  end
end
