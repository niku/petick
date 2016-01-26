defmodule Petick.WorkerTest do
  use ExUnit.Case, async: true

  @interval 100 # 0.1sec

  test "gets config" do
    callback = fn x -> x end
    {:ok, worker} = Petick.Worker.start_link([callback: callback, interval: @interval])
    assert {%Petick.Config{callback: ^callback, interval: @interval}, _next_tick} = GenServer.call(worker, :get)
  end
end
