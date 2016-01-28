defmodule Petick.WorkerTest do
  use ExUnit.Case, async: true

  @interval 100 # 0.1sec

  test "gets config" do
    callback = fn x -> x end
    {:ok, worker} = Petick.Worker.start_link([callback: callback, interval: @interval])
    assert {%Petick.Config{callback: ^callback, interval: @interval}, _next_tick} = GenServer.call(worker, :get)
  end

  test "periodick callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, _worker} = Petick.Worker.start_link([callback: callback, interval: @interval])
    [first, second, third] = Enum.take(GenEvent.stream(manager), 3)
    delta1 = abs((second - first) / @interval)
    delta2 = abs((third - second) / @interval)
     # less than 10%
    assert delta1 < 1.1
    assert delta2 < 1.1
  end

  test "stop callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, worker} = Petick.Worker.start_link([callback: callback, interval: @interval])
    Enum.take(GenEvent.stream(manager), 1) # wait callback at least once
    :ok = Petick.Worker.stop(worker) # stop callback
    # no callback called, so the stream is timeout
    assert {:timeout, _} = catch_exit(Enum.to_list(GenEvent.stream(manager, timeout: @interval * 3)))
  end
end
