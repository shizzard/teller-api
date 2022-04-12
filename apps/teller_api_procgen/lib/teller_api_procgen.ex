defmodule TellerApiProcgen do
  defmodule Cfg do
    @type t() :: %__MODULE__{}
    @enforce_keys [
      :secret_key,
      :secret_key_base,
      :today_date,
      :accounts_max,
      :accounts_id_base,
      :accounts_enrollment_id_base,
      :accounts_routing_numbers_ach,
      :days_per_account,
      :trxs_per_day,
      :trxs_id_base,
      :trxs_amount_min,
      :trxs_amount_max,
      :trxs_status_posted_chance,
      :trxs_processing_status_complete_chance
    ]
    defstruct [
      :secret_key,
      :secret_key_base,
      :today_date,
      :accounts_max,
      :accounts_id_base,
      :accounts_enrollment_id_base,
      :accounts_routing_numbers_ach,
      :days_per_account,
      :trxs_per_day,
      :trxs_id_base,
      :trxs_amount_min,
      :trxs_amount_max,
      :trxs_status_posted_chance,
      :trxs_processing_status_complete_chance
    ]
  end

  defmodule RngState do
    @type t() :: %__MODULE__{}
    @enforce_keys [:rng_state]
    defstruct [:rng_state]
  end

  @default_algorithm :exsss

  @spec init_state(
          seed_a :: pos_integer(),
          seed_b :: pos_integer(),
          seed_c :: pos_integer()
        ) :: RngState.t()
  def init_state(seed_a, seed_b, seed_c),
    do: init_state(@default_algorithm, seed_a, seed_b, seed_c)

  @spec init_state(
          algo :: :rand.builtin_alg(),
          seed_a :: pos_integer(),
          seed_b :: pos_integer(),
          seed_c :: pos_integer()
        ) :: RngState.t()
  def init_state(algo, seed_a, seed_b, seed_c) do
    %RngState{rng_state: :rand.seed_s(algo, {seed_a, seed_b, seed_c})}
  end

  @spec integer(
          s :: RngState.t(),
          upper_bound :: pos_integer()
        ) :: {s :: RngState.t(), x :: pos_integer()}
  def integer(%RngState{rng_state: rng_s} = s, upper_bound)
      when is_integer(upper_bound) do
    {x, rng_s} = :rand.uniform_s(upper_bound, rng_s)
    {%RngState{s | rng_state: rng_s}, x}
  end

  @spec integer(
          s :: RngState.t(),
          lower_bound :: pos_integer(),
          upper_bound :: pos_integer()
        ) :: {s :: RngState.t(), x :: pos_integer()}
  def integer(%RngState{rng_state: rng_s} = s, lower_bound, upper_bound)
      when is_integer(lower_bound) and is_integer(upper_bound) and lower_bound < upper_bound do
    {x, rng_s} = :rand.uniform_s(upper_bound - (lower_bound - 1), rng_s)
    {%RngState{s | rng_state: rng_s}, x + (lower_bound - 1)}
  end

  @spec boolean(
          s :: RngState.t(),
          true_chance :: float()
        ) :: {s :: RngState.t(), x :: pos_integer()}
  def boolean(%RngState{rng_state: rng_s} = s, tc)
      when is_float(tc) and tc >= 0.0 and tc <= 1.0 do
    {x, rng_s} = :rand.uniform_s(rng_s)
    {%RngState{s | rng_state: rng_s}, x < tc}
  end

  @spec decimal(
          s :: RngState.t(),
          lower_bound :: pos_integer(),
          upper_bound :: pos_integer(),
          decimal_places :: 1..10
        ) :: {s :: RngState.t(), x :: float()}
  def decimal(s, lower_bound, upper_bound, decimal_places)
      when is_integer(decimal_places) and decimal_places >= 1 and decimal_places <= 10 do
    multiplier = 10 ** decimal_places
    {s, x} = integer(s, lower_bound * multiplier, upper_bound * multiplier)
    {s, Decimal.div(x, multiplier)}
  end

  @spec element(
          s :: RngState.t(),
          list :: [term(), ...]
        ) :: {s :: RngState.t(), nth :: term()}
  def element(s, list) when is_list(list) and length(list) > 0 do
    {s, nth} = integer(s, length(list))
    {s, Enum.at(list, nth - 1)}
  end

  @spec map(
          s :: RngState.t(),
          generator_map :: %{(k :: term()) => v :: (RngState.t() -> {RngState.t(), term()})}
        ) :: {s :: RngState.t(), %{(k :: term()) => v :: term()}}
  def map(s, generator_map), do: Enum.reduce(generator_map, {s, %{}}, &map_reduce/2)

  defp map_reduce({k, generator}, {s, acc}) do
    {s_mut, v} = generator.(s)
    {s_mut, Map.put(acc, k, v)}
  end
end
