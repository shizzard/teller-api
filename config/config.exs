import Config

config :teller_api_procgen,
  secret_key_b36: System.get_env("TELLER_API_PROCGEN_SECRET_KEY_B36") || "defaultsecretkey",
  secret_key_b36_base:
    (System.get_env("TELLER_API_PROCGEN_SECRET_KEY_B36_BASE") || "64")
    |> String.to_integer(),
  accounts_id_base:
    (System.get_env("TELLER_API_PROCGEN_ACCOUNTS_ID_BASE") || "32")
    |> String.to_integer(),
  accounts_enrollment_id_base:
    (System.get_env("TELLER_API_PROCGEN_ACCOUNTS_ENROLLMENT_ID_BASE") || "32")
    |> String.to_integer(),
  accounts_routing_numbers_ach:
    (System.get_env("TELLER_API_PROCGEN_ACCOUNTS_ROUTING_NUMBERS_ACH") || "32")
    |> String.to_integer(),
  accounts_per_token_max:
    (System.get_env("TELLER_API_PROCGEN_ACCOUNTS_PER_TOKEN_MAX") || "5")
    |> String.to_integer(),
  transactions_id_base:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_ID_BASE") || "32")
    |> String.to_integer(),
  transactions_days_per_account:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_DAYS_PER_ACCOUNT") || "90")
    |> String.to_integer(),
  transactions_per_day_max:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_PER_DAY_MAX") || "5")
    |> String.to_integer(),
  transactions_amount_min:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MIN") || "10")
    |> String.to_integer(),
  transactions_amount_max:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_AMOUNT_MAX") || "100")
    |> String.to_integer(),
  transactions_status_posted_chance:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_STATUS_POSTED_CHANCE") || "0.8")
    |> String.to_float(),
  transactions_processing_status_complete_chance:
    (System.get_env("TELLER_API_PROCGEN_TRANSACTIONS_PROCESSING_STATUS_COMPLETE_CHANCE") || "0.9")
    |> String.to_float()

config :teller_api_http,
  proto: System.get_env("TELLER_API_HTTP_PROTO") || "http",
  host: System.get_env("TELLER_API_HTTP_HOST") || "localhost",
  cache_limit:
    (System.get_env("TELLER_API_HTTP_CACHE_LIMIT") || "1000")
    |> String.to_integer(),
  cache_lifetime_sec:
    (System.get_env("TELLER_API_HTTP_CACHE_LIFETIME_SEC") || "1800")
    |> String.to_integer()

config :logger,
  handle_otp_reports: true,
  backends: [:console, {LoggerFileBackend, :file}],
  sync_threshold: 1000,
  handle_sasl_reports: false

config :logger, :console,
  level: :critical

config :logger, :file,
  level: (System.get_env("TELLER_API_LOGGER_LEVEL") || "error") |> String.to_atom(),
  path:  (System.get_env("TELLER_API_LOGGER_DIR") || ".") <> "/file.log"
