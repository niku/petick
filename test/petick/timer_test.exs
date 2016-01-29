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
    assert is_integer(next_tick) and next_tick <= @interval
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
