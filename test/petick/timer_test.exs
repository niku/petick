defmodule Petick.TimerTest do
  use ExUnit.Case, async: true
  @moduletag timeout: 3_000 # 3.0 sec

  @interval 10 # 0.01sec
  @delta 1.5 # 150%
  @wait_for_timeout @interval * 3

  test "gets config and next tick" do
    callback = fn x -> x end
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    assert {%Petick.Config{callback: ^callback, interval: @interval}, next_tick} = GenServer.call(timer, :get)
    # When a timer is expired, false binds to the next_tick.
    assert (is_integer(next_tick) and next_tick <= @interval) or (next_tick == false)
  end

  test "gets config and next tick when callback is {Module, function} style", %{test: module_name} do
    defmodule module_name do
      def mycallback(_pid) do
        "do callback"
      end
    end

    callback = {module_name, :mycallback}
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    assert {%Petick.Config{callback: ^callback, interval: @interval}, _next_tick} = GenServer.call(timer, :get)
  end

  test "periodick callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [first, second, third] = Enum.take(GenEvent.stream(manager), 3)
    delta1 = abs((second - first) / @interval)
    delta2 = abs((third - second) / @interval)
    assert delta1 < @delta
    assert delta2 < @delta
  end

  test "periodic callback when callback is {Module, function} style ", %{test: module_name} do
    defmodule MyGenEvent do
      def start_link, do: GenEvent.start_link(name: __MODULE__)
      def notify(v), do: GenEvent.notify(__MODULE__, v)
      def stream, do: GenEvent.stream(__MODULE__)
    end

    defmodule module_name do
      def mycallback(_pid) do
        MyGenEvent.notify(:os.system_time(:milli_seconds))
      end
    end

    {:ok, _manager} = MyGenEvent.start_link
    {:ok, _timer} = Petick.Timer.start_link([callback: {module_name, :mycallback}, interval: @interval])
    [first, second, third] = Enum.take(MyGenEvent.stream, 3)
    delta1 = abs((second - first) / @interval)
    delta2 = abs((third - second) / @interval)
    assert delta1 < @delta
    assert delta2 < @delta
  end

  test "periodic callback even if callback is slow" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid ->
      :timer.sleep(@wait_for_timeout)
      GenEvent.notify(manager, :os.system_time(:milli_seconds))
    end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [first, second, third] = Enum.take(GenEvent.stream(manager), 3)
    delta1 = abs((second - first) / @interval)
    delta2 = abs((third - second) / @interval)
    assert delta1 < @delta
    assert delta2 < @delta
  end

  @tag capture_log: true
  test "periodic callback even if raise error in a callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid ->
      GenEvent.notify(manager, :os.system_time(:milli_seconds))
      raise "boom!"
    end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [first, second, third] = Enum.take(GenEvent.stream(manager), 3)
    delta1 = abs((second - first) / @interval)
    delta2 = abs((third - second) / @interval)
    assert delta1 < @delta
    assert delta2 < @delta
  end

  test "stop callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    Enum.take(GenEvent.stream(manager), 1) # wait callback at least once
    :ok = Petick.Timer.stop(timer) # stop callback
    # no callback called, so the stream is timeout
    assert {:timeout, _} = catch_exit(Enum.to_list(GenEvent.stream(manager, timeout: @wait_for_timeout)))
  end
end
