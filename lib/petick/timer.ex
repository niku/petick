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

  def handle_info(:tick, {state, _old_timer_ref}) do
    Task.Supervisor.start_child(Petick.TaskSupervisor, fn -> state.callback.(self) end)
    timer_ref = Process.send_after(self, :tick, state.interval)
    {:noreply, {state, timer_ref}}
  end
end
