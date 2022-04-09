defmodule TellerApiHttpTest do
  use ExUnit.Case
  doctest TellerApiHttp

  test "greets the world" do
    assert TellerApiHttp.hello() == :world
  end
end
