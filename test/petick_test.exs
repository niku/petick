defmodule PetickTest do
  use ExUnit.Case

  @tag capture_log: true
  setup do
    Application.stop(:petick)
    :ok = Application.start(:petick)
  end

  test "lists timers and each timer are represented by tuple that has three elements." do
    callback1 = fn x -> IO.inspect x end
    interval1 = 3000
    {:ok, pid1} = Petick.start_child([[callback: callback1, interval: interval1]])

    callback2 = fn _x -> IO.inspect :os.timestamp end
    interval2 = 5000
    {:ok, _pid2} = Petick.start_child([[callback: callback2, interval: interval2]])

    list = [{pid, config, next_tick}|_rest] = Petick.list

    assert length(list) == 2
    assert pid == pid1
    assert config == %Petick.Config{callback: callback1, interval: interval1}
    assert_in_delta next_tick, interval1, 100
  end
end
