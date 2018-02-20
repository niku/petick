defmodule PetickTest do
  use ExUnit.Case
  # 3.0 sec
  @moduletag timeout: 3_000
  @moduletag :capture_log

  setup do
    Application.stop(:petick)
    :ok = Application.start(:petick)
  end

  test "lists timers" do
    callback1 = fn x -> IO.inspect(x) end
    interval1 = 3000
    {:ok, _pid1} = Petick.start(callback: callback1, interval: interval1)

    callback2 = fn _x -> IO.inspect(:os.timestamp()) end
    interval2 = 5000
    {:ok, _pid2} = Petick.start(callback: callback2, interval: interval2)

    assert length(Petick.list()) == 2
  end

  test "gets timer configuration represented by a tuple that has two elements." do
    callback1 = fn x -> IO.inspect(x) end
    interval1 = 3000
    {:ok, pid1} = Petick.start(callback: callback1, interval: interval1)

    callback2 = fn _x -> IO.inspect(:os.timestamp()) end
    interval2 = 5000
    {:ok, _pid2} = Petick.start(callback: callback2, interval: interval2)

    pid = Enum.find(Petick.list(), &(&1 == pid1))

    {config, next_tick} = Petick.get(pid)
    assert config == %Petick.Timer.Config{callback: callback1, interval: interval1}
    assert_in_delta next_tick, interval1, 100
  end

  test "terminates timer." do
    callback1 = fn x -> IO.inspect(x) end
    interval1 = 3000
    {:ok, pid1} = Petick.start(callback: callback1, interval: interval1)

    callback2 = fn _x -> IO.inspect(:os.timestamp()) end
    interval2 = 5000
    {:ok, pid2} = Petick.start(callback: callback2, interval: interval2)

    Petick.terminate(pid1)

    list = Petick.list()
    assert length(list) == 1
    assert hd(list) == pid2
  end

  test "changes interval." do
    old_interval = 10
    new_interval = old_interval * 5

    {:ok, manager} = GenEvent.start_link()
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, timer} = Petick.Timer.start_link(callback: callback, interval: old_interval)

    Petick.change_interval(timer, new_interval)

    GenEvent.stream(manager)
    |> Stream.chunk(2, 1)
    |> Enum.find(fn [a, b] -> new_interval < b - a end)

    assert true, "We found large interval, so reach here."
  end
end
