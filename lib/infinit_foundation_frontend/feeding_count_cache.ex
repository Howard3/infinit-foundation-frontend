defmodule InfinitFoundationFrontend.FeedingCountCache do
  @moduledoc """
  ETS-backed cache for the feeding count from the external API.
  Caches the result for 1 hour to avoid unnecessary API hits.
  """
  use GenServer

  alias InfinitFoundationFrontend.ApiClient

  @table :feeding_count_cache
  @cache_ttl_ms :timer.hours(1)

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns the cached feeding count, fetching from the API if the cache is stale or empty.
  Returns `{:ok, count}` or `{:error, reason}`.
  """
  def get_feeding_count do
    case lookup_cache() do
      {:ok, _count} = result -> result
      :miss -> GenServer.call(__MODULE__, :fetch)
    end
  end

  # Server callbacks

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, %{}, {:continue, :initial_fetch}}
  end

  @impl true
  def handle_continue(:initial_fetch, state) do
    fetch_and_cache()
    {:noreply, state}
  end

  @impl true
  def handle_call(:fetch, _from, state) do
    # Double-check cache in case another call already populated it
    case lookup_cache() do
      {:ok, _count} = result ->
        {:reply, result, state}

      :miss ->
        {:reply, fetch_and_cache(), state}
    end
  end

  # Private

  defp lookup_cache do
    case :ets.lookup(@table, :feeding_count) do
      [{:feeding_count, count, expiry}] ->
        if System.monotonic_time(:millisecond) < expiry do
          {:ok, count}
        else
          :miss
        end

      [] ->
        :miss
    end
  end

  defp fetch_and_cache do
    case ApiClient.get_feeding_count() do
      {:ok, count} ->
        expiry = System.monotonic_time(:millisecond) + @cache_ttl_ms
        :ets.insert(@table, {:feeding_count, count, expiry})
        {:ok, count}

      {:error, _reason} = error ->
        error
    end
  end
end
