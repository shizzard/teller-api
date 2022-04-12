defmodule TellerApiHttp.Metrics do
  defmodule State do
    defstruct [:timer_ref, :ref]
  end

  defmodule Ref do
    defstruct ref: nil
  end

  use GenServer
  require Logger
  alias TellerApiHttp, as: TAH

  @metric_teller_api_cache_rate :teller_api_cache_rate
  @label_teller_api_cache_rate_type :type
  @label_value_teller_api_cache_rate_hit :hit
  @label_value_teller_api_cache_rate_miss :miss

  @metric_teller_api_cache_calls :teller_api_cache_calls
  @label_teller_api_cache_calls_type :type
  @label_value_teller_api_cache_calls_fetch :fetch
  @label_value_teller_api_cache_calls_purge :purge
  @label_value_teller_api_cache_calls_stats :stats

  @interval 10

  def declare_metrics() do
    :prometheus_gauge.new([
      {:name, @metric_teller_api_cache_rate},
      {:labels, [@label_teller_api_cache_rate_type]},
      {:help, "Teller API cache rates"}
    ])

    :prometheus_gauge.new([
      {:name, @metric_teller_api_cache_calls},
      {:labels, [@label_teller_api_cache_calls_type]},
      {:help, "Teller API cache calls"}
    ])
  end

  def start_link([]), do: GenServer.start_link(__MODULE__, [])

  @impl true
  def init([]) do
    {ref, timer_ref} = init_timer(@interval)
    {:ok, %State{timer_ref: timer_ref, ref: ref}}
  end

  @impl true
  def handle_info(%Ref{ref: ref_to_check}, %State{ref: ref_to_check} = state) do
    Logger.debug("Reporting metrics")
    :ok = report_metrics()
    {new_ref, new_timer_ref} = init_timer(@interval)
    {:noreply, %{state | timer_ref: new_timer_ref, ref: new_ref}}
  end

  def handle_info(%Ref{} = _invalid_ref, state), do: {:noreply, state}

  def handle_info(info, state) do
    Logger.error("Unhandled info: #{info}")
    {:noreply, state}
  end

  defp init_timer(interval) do
    ref = Kernel.make_ref()
    timer_ref = Process.send_after(self(), %Ref{ref: ref}, interval * 1000)
    {ref, timer_ref}
  end

  defp report_metrics() do
    {:ok, cachex_metrics} = TAH.token_cache_stats()
    calls_fetch = cachex_metrics |> Map.get(:calls, %{}) |> Map.get(:fetch, 0)
    calls_purge = cachex_metrics |> Map.get(:calls, %{}) |> Map.get(:purge, 0)
    calls_stats = cachex_metrics |> Map.get(:calls, %{}) |> Map.get(:stats, 0)
    rate_hit = cachex_metrics |> Map.get(:hit_rate, 0.0)
    rate_miss = cachex_metrics |> Map.get(:miss_rate, 0.0)

    :prometheus_gauge.set(
      @metric_teller_api_cache_calls,
      [@label_value_teller_api_cache_calls_fetch],
      calls_fetch
    )

    :prometheus_gauge.set(
      @metric_teller_api_cache_calls,
      [@label_value_teller_api_cache_calls_purge],
      calls_purge
    )

    :prometheus_gauge.set(
      @metric_teller_api_cache_calls,
      [@label_value_teller_api_cache_calls_stats],
      calls_stats
    )

    :prometheus_gauge.set(
      @metric_teller_api_cache_rate,
      [@label_value_teller_api_cache_rate_hit],
      rate_hit
    )

    :prometheus_gauge.set(
      @metric_teller_api_cache_rate,
      [@label_value_teller_api_cache_rate_miss],
      rate_miss
    )

    :ok
  end
end
