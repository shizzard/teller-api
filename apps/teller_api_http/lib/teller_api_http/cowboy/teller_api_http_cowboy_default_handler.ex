defmodule TellerApiHttp.Cowboy.DefaultHandler do
  alias TellerApiHttp.Static, as: Static
  alias TellerApiHttp.Cowboy.Common, as: Common

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)

  def to_json(req, state) do
    req =
      :cowboy_req.reply(
        404,
        Common.teller_api_headers(),
        Jason.encode!(Static.error_not_found()),
        req
      )

    {:stop, req, state}
  end
end
