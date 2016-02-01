defmodule PetickTest do
  use ExUnit.Case

  @tag capture_log: true
  setup do
    Application.stop(:petick)
    :ok = Application.start(:petick)
  end

  setup do
    callback1 = fn x -> IO.inspect x end
    interval1 = 3000
    {:ok, pid1} = Petick.start_child([[callback: callback1, interval: interval1]])

    callback2 = fn _x -> IO.inspect :os.timestamp end
    interval2 = 5000
    {:ok, pid2} = Petick.start_child([[callback: callback2, interval: interval2]])

    {:ok, [first: %{callback: callback1, interval: interval1, pid: pid1},
           second: %{callback: callback2, interval: interval2, pid: pid2}]}
  end

  test "lists timers which is represented by tuple that has three elements.", context do
    list = Petick.list
    [{pid, config, next_tick}|_rest] = list

    assert length(list) == 2
    assert pid == context[:first][:pid]
    assert config == %Petick.Config{callback: context[:first][:callback], interval: context[:first][:interval]}
    assert_in_delta next_tick, context[:first][:interval], 100
  end
end
