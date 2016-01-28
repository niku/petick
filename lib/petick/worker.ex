defmodule Petick.Worker do
  use GenServer

  def start_link(args, options \\ []) do
    GenServer.start_link(__MODULE__, args, options)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  def init([callback: callback, interval: interval]) do
    config = %Petick.Config{callback: callback, interval: interval}
    timer_ref = Process.send_after(self, :tick, interval)
    {:ok, {config, timer_ref}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:tick, {state, _old_timer_ref}) do
    Task.start(fn -> state.callback.(self) end)
    timer_ref = Process.send_after(self, :tick, state.interval)
    {:noreply, {state, timer_ref}}
  end
end
