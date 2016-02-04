defmodule Petick.Timer do
  use GenServer

  def start_link(args, options \\ []) do
    GenServer.start_link(__MODULE__, args, options)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def get_config(server) do
    GenServer.call(server, :get)
  end

  def change_interval(server, interval) when is_integer(interval) and 0 < interval do
    GenServer.cast(server, {:change_interval, interval})
  end

  def init([callback: callback, interval: interval]) do
    config = %Petick.Config{callback: callback, interval: interval}
    timer_ref = Process.send_after(self, :tick, interval)
    {:ok, {config, timer_ref}}
  end

  def handle_call(:get, _from, state) do
    {config, timer_ref} = state
    next_tick = Process.read_timer(timer_ref)
    {:reply, {config, next_tick}, state}
  end

  def handle_cast({:change_interval, interval}, state) do
    {config, timer_ref} = state
    Process.cancel_timer(timer_ref)
    timer_ref = Process.send_after(self, :tick, interval)
    {:noreply, {%{config | interval: interval}, timer_ref}}
  end

  def handle_info(:tick, {state, _old_timer_ref}) do
    case state.callback do
      {m, f} -> Task.Supervisor.start_child(Petick.TaskSupervisor, m, f, [self])
      f when is_function(f) -> Task.Supervisor.start_child(Petick.TaskSupervisor, fn -> f.(self) end)
    end
    timer_ref = Process.send_after(self, :tick, state.interval)
    {:noreply, {state, timer_ref}}
  end
end
