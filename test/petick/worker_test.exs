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
end
