defmodule TellerApiHttp.Cowboy.RootHandler do
  alias TellerApiHttp.Cowboy.Common, as: Common

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)
  def is_authorized(req, state), do: Common.cb_is_authorized(req, state)

  def to_json(req, state) do
    req = :cowboy_req.reply(200, Common.teller_api_headers(), Jason.encode!(body()), req)

    {:stop, req, state}
  end

  defp body(), do: %{links: %{accounts: TellerApiHttp.link_accounts()}}
end
