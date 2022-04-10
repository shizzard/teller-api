defmodule TellerApiHttp.Cowboy.Common do
  defmodule State do
    @state_key_auth_token :common_state_key_auth_token
    @state_key_request_id :common_state_key_request_id
    def auth_token(state), do: Map.fetch!(state, @state_key_auth_token)
    def auth_token(state, value), do: Map.put(state, @state_key_auth_token, value)
    def request_id(state), do: Map.fetch!(state, @state_key_request_id)
    def request_id(state, value), do: Map.put(state, @state_key_request_id, value)
  end

  use Bitwise
  require Logger
  alias TellerApiHttp.Static, as: Static

  def cb_init(req, state) do
    request_id = generate_request_id()
    Logger.info("[#{request_id}] request '#{:cowboy_req.path(req)}' qs '#{:cowboy_req.qs(req)}'")
    {:cowboy_rest, req, State.request_id(state, request_id)}
  end

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

  def respond(code, body, req, state), do: respond(code, [], body, req, state)

  def respond(code, headers, body, req, state) do
    Logger.info("[#{State.request_id(state)}] response #{code}")
    :cowboy_req.reply(code, headers ++ teller_api_headers(state), Jason.encode!(body), req)
  end

  defp teller_api_headers(state),
    do: %{
      "content-type" => "application/json",
      "server" => "Teller API",
      "teller-enrollment-status" => "healthy",
      "x-request-id" => State.request_id(state)
    }

  defp is_authorized_check_token(token, req, state) do
    case TellerApiProcgen.Token.valid?(token, TellerApiProcgen.Static.config()) do
      true -> {true, req, State.auth_token(state, token)}
      false -> is_authorized_forbidden(req, state)
    end
  end

  defp is_authorized_forbidden(req, state) do
    req = respond(401, Static.error_forbidden(), req, state)
    {:stop, req, state}
  end

  defp generate_request_id(),
    do: ((1 <<< 64) - 1) |> :rand.uniform() |> TellerApiProcgen.Base36.encode()
end
