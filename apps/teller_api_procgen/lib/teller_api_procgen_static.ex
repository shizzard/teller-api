defmodule TellerApiProcgen.Static do
  use Bitwise
  alias TellerApiProcgen.Base36, as: Base36
  alias TellerApiProcgen.Cfg, as: Cfg

  @merchants ("Uber,Uber Eats,Lyft,Five Guys,In-N-Out Burger,Chick-Fil-A,AMC Metreon," <>
                "Apple,Amazon,Walmart,Target,Hotel Tonight,Misson Ceviche,The Creamery," <>
                "Caltrain,Wingstop,Slim Chickens,CVS,Duane Reade,Walgreens,Rooster & Rice," <>
                "McDonald's,Burger King,KFC,Popeye's,Shake Shack,Lowe's,The Home Depot," <>
                "Costco,Kroger,iTunes,Spotify,Best Buy,TJ Maxx,Aldi,Dollar General," <>
                "Macy's,H.E. Butt,Dollar Tree,Verizon Wireless,Sprint PCS,T-Mobile,Kohl's," <>
                "Starbucks,7-Eleven,AT&T Wireless,Rite Aid,Nordstrom,Ross,Gap," <>
                "Bed,Bath & Beyond,J.C. Penney,Subway,O'Reilly,Wendy's,Dunkin' Donuts," <>
                "Petsmart,Dick's Sporting Goods,Sears,Staples,Domino's Pizza,Pizza Hut," <>
                "Papa John's,IKEA,Office Depot,Foot Locker,Lids,GameStop,Sephora,MAC," <>
                "Panera,Williams-Sonoma,Saks Fifth Avenue,Chipotle Mexican Grill,Exxon Mobil," <>
                "Neiman Marcus,Jack In The Box,Sonic,Shell")
             |> String.split(",")

  @merchant_categories ("accommodation,advertising,bar,charity,clothing,dining,education,electronics," <>
                          "entertainment,fuel,groceries,health,home,income,insurance,investment,loan," <>
                          "office,phone,service,shopping,software,sport,tax,transport,transportation," <>
                          "utilities")
                       |> String.split(",")

  @account_names ("My Checking,Jimmy Carter,Ronald Reagan,George H. W. Bush," <>
                    "Bill Clinton,George W. Bush,Barack Obama,Donald Trump")
                 |> String.split(",")

  @institutions ["Chase", "Bank of America", "Wells Fargo", "Citibank", "Capital One"]

  @spec hash_base() :: pos_integer()
  def hash_base(), do: 32

  @spec hash(term :: term()) :: pos_integer()
  def hash(term), do: :erlang.crc32(:erlang.term_to_binary(term))

  @spec config() :: Cfg.t()
  def config() do
    %Cfg{
      secret_key: secret_key(),
      secret_key_base: secret_key_base(),
      today_date: Date.utc_today() |> Date.to_gregorian_days(),
      accounts_max: Application.get_env(:teller_api_procgen, :accounts_per_token_max),
      accounts_id_base: Application.get_env(:teller_api_procgen, :accounts_id_base),
      accounts_enrollment_id_base:
        Application.get_env(:teller_api_procgen, :accounts_enrollment_id_base),
      accounts_routing_numbers_ach:
        Application.get_env(:teller_api_procgen, :accounts_routing_numbers_ach),
      days_per_account: Application.get_env(:teller_api_procgen, :transactions_days_per_account),
      trxs_per_day: Application.get_env(:teller_api_procgen, :transactions_per_day_max),
      trxs_id_base: Application.get_env(:teller_api_procgen, :transactions_id_base),
      trxs_amount_min: Application.get_env(:teller_api_procgen, :transactions_amount_min),
      trxs_amount_max: Application.get_env(:teller_api_procgen, :transactions_amount_max),
      trxs_status_posted_chance:
        Application.get_env(:teller_api_procgen, :transactions_status_posted_chance),
      trxs_processing_status_complete_chance:
        Application.get_env(:teller_api_procgen, :transactions_processing_status_complete_chance)
    }
  end

  @spec merchants() :: [String.t()]
  def merchants(), do: @merchants

  @spec merchant_categories() :: [String.t()]
  def merchant_categories(), do: @merchant_categories

  @spec account_names() :: [String.t()]
  def account_names(), do: @account_names

  @spec institutions() :: [String.t()]
  def institutions(), do: @institutions

  @spec secret_key_base() :: pos_integer()
  defp secret_key_base(), do: Application.get_env(:teller_api_procgen, :secret_key_b36_base)

  @spec secret_key() :: pos_integer()
  defp secret_key() do
    case Base36.decode(Application.get_env(:teller_api_procgen, :secret_key_b36)) do
      :error -> {:error, :failed_to_decode_secret_key}
      {:ok, key} -> {:ok, rem(key, 1 <<< secret_key_base())}
    end
  end
end
