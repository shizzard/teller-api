defmodule TellerApiHttp.Static do
  @error_code_not_found "not_found"
  @error_message_not_found "The requested resource does not exist"
  @error_code_forbidden "forbidden"
  @error_message_forbidden "Authorization token invalid"

  @spec error(code :: String.t(), message: String.t()) :: map()
  def error(code, message), do: %{error: %{code: code, message: message}}

  def error_not_found(), do: error(@error_code_not_found, @error_message_not_found)
  def error_forbidden(), do: error(@error_code_forbidden, @error_message_forbidden)
end
