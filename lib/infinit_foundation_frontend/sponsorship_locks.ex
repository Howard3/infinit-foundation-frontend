defmodule InfinitFoundationFrontend.SponsorshipLocks do
  use GenServer
  require Logger

  @table_name :sponsorship_locks
  @lock_timeout 15
  @lock_timeout_unit :minute

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def request_lock(student_id, holder_id) do
    GenServer.call(__MODULE__, {:request_lock, student_id, holder_id})
  end

  def release_lock(student_id, holder_id) do
    GenServer.cast(__MODULE__, {:release_lock, student_id, holder_id})
  end

  def extend_lock(student_id, holder_id) do
    GenServer.call(__MODULE__, {:extend_lock, student_id, holder_id})
  end

  def check_locks(student_ids, holder_id) when is_list(student_ids) do
    GenServer.call(__MODULE__, {:check_locks, student_ids, holder_id})
  end

  def get_lock_info(student_id) do
    GenServer.call(__MODULE__, {:get_lock_info, student_id})
  end

  # Server callbacks

  @impl true
  def init(state) do
    Logger.info("Starting SponsorshipLocks GenServer with initial state: #{inspect(state)}")
    :ets.new(@table_name, [:set, :protected, :named_table])
    {:ok, state}
  end

  @impl true
  def handle_call({:request_lock, student_id, holder_id}, _from, state) do
    case :ets.lookup(@table_name, student_id) do
      [] ->
        put_lock(student_id, holder_id)
        {:reply, :ok, state}

      [{_student_id, ^holder_id, _expiry}] ->
        # Already locked by this holder, extend it
        put_lock(student_id, holder_id)
        {:reply, :ok, state}

      [{_student_id, ^holder_id, expiry}] ->
        put_lock(student_id, holder_id)
        {:reply, :ok, state}

      _ ->
        {:reply, {:error, :already_locked}, state}
    end
  end

  @impl true
  def handle_call({:extend_lock, student_id, holder_id}, _from, state) do
    case :ets.lookup(@table_name, student_id) do
      [{^student_id, ^holder_id, _expiry}] ->
        put_lock(student_id, holder_id)
        {:reply, :ok, state}
      _ ->
        {:reply, {:error, :not_lock_holder}, state}
    end
  end

  @impl true
  def handle_cast({:release_lock, student_id, holder_id}, state) do
    Logger.info("Releasing lock for student #{student_id} by holder #{holder_id}")
    case :ets.lookup(@table_name, student_id) do
      [{^student_id, ^holder_id, _expiry}] ->
        :ets.delete(@table_name, student_id)
        {:noreply, state}
      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:check_locks, student_ids, holder_id}, _from, state) do
    result = Enum.map(student_ids, fn student_id ->
      case :ets.lookup(@table_name, student_id) do
        [] ->
          :free
        [{_student_id, ^holder_id, _expiry}] ->
          :reserved_for_user
        [{_student_id, _other_holder, _expiry}] ->
          :locked
      end
    end)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_lock_info, student_id}, _from, state) do
    case :ets.lookup(@table_name, student_id) do
      [{^student_id, _holder_id, expiry}] ->
        {:reply, {:ok, expiry}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  # Helper functions

  defp put_lock(student_id, holder_id) do
    Logger.info("Putting lock for student #{student_id} by holder #{holder_id}")
    expiry = DateTime.add(DateTime.utc_now(), @lock_timeout, @lock_timeout_unit)
    remove_locks_for_holder(holder_id)
    :ets.insert(@table_name, {student_id, holder_id, expiry})
  end

  defp remove_locks_for_holder(holder_id) do
    :ets.match_delete(@table_name, {:_, holder_id, :_})
  end
end
