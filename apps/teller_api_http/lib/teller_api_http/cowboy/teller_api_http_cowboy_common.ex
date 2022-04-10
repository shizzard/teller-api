defmodule TellerApiHttp.Cowboy.Common do
  defmodule State do
    @state_key_auth_token :common_state_key_auth_token
    def auth_token(state), do: Map.fetch!(state, @state_key_auth_token)
    def auth_token(state, value), do: Map.put(state, @state_key_auth_token, value)
  end

  alias TellerApiHttp.Static, as: Static
  require Logger

  def cb_init(req, state), do: {:cowboy_rest, req, state}
  def cb_allowed_methods(req, state), do: {["GET", "HEAD"], req, state}
  def cb_known_methods(req, state), do: {["GET", "HEAD"], req, state}

  def cb_content_types_provided(req, state),
    do: {[{{"application", "json", :*}, :to_json}], req, state}

  def cb_charsets_provided(req, state), do: {["utf-8"], req, state}

  def cb_is_authorized(req, state) do
    case :cowboy_req.parse_header("authorization", req) do
      {:basic, token, _} -> is_authorized_check_token(token, req, state)
      _ -> is_authorized_forbidden(req, state)
    end
  end

  def teller_api_headers(), do: %{"content-type" => "application/json"}

  defp is_authorized_check_token(token, req, state) do
    case TellerApiProcgen.Token.valid?(token, TellerApiProcgen.Static.config()) do
      true -> {true, req, State.auth_token(state, token)}
      false -> is_authorized_forbidden(req, state)
    end
  end

  defp is_authorized_forbidden(req, state) do
    req =
      :cowboy_req.reply(
        401,
        teller_api_headers(),
        Jason.encode!(Static.error_forbidden()),
        req
      )

    {:stop, req, state}
  end
end
