defmodule TellerApiHttp.Cowboy.DefaultHandler do
  require Logger
  alias TellerApiHttp.Static, as: Static
  alias TellerApiHttp.Cowboy.Common, as: Common

  def init(req, state), do: Common.cb_init(req, state)
  def allowed_methods(req, state), do: Common.cb_allowed_methods(req, state)
  def known_methods(req, state), do: Common.cb_known_methods(req, state)
  def content_types_provided(req, state), do: Common.cb_content_types_provided(req, state)
  def charsets_provided(req, state), do: Common.cb_charsets_provided(req, state)

  def to_json(req, state) do
    req = Common.respond(404, Static.error_not_found(), req, state)

    {:stop, req, state}
  end
end
