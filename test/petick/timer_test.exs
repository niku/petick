defmodule Petick.TimerTest do
  use ExUnit.Case, async: true
  @moduletag timeout: 3_000 # 3.0 sec

  @interval 30 # 0.03sec
  @delta_ratio 70..130 # 70-130%
  @wait_for_timeout @interval * 3

  test "gets config and next tick" do
    callback = fn x -> x end
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    assert {%Petick.Timer.Config{callback: ^callback, interval: @interval}, next_tick} = GenServer.call(timer, :get)
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
    assert {%Petick.Timer.Config{callback: ^callback, interval: @interval}, _next_tick} = GenServer.call(timer, :get)
  end

  test "periodick callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [delta1, delta2] = GenEvent.stream(manager)
                       |> Stream.chunk(2, 1)
                       |> Enum.take(2)
                       |> Enum.map(fn [a, b] -> b - a end)
    assert div(delta1 * 100, @interval) in @delta_ratio
    assert div(delta2 * 100, @interval) in @delta_ratio
  end

  test "periodic callback when callback is {Module, function} style ", %{test: module_name} do
    defmodule MyGenEvent do
      def start_link, do: GenEvent.start_link(name: __MODULE__)
      def notify(v), do: GenEvent.notify(__MODULE__, v)
    end

    defmodule module_name do
      def mycallback(_pid) do
        MyGenEvent.notify(:os.system_time(:milli_seconds))
      end
    end

    {:ok, manager} = MyGenEvent.start_link
    {:ok, _timer} = Petick.Timer.start_link([callback: {module_name, :mycallback}, interval: @interval])
    [delta1, delta2] = GenEvent.stream(manager)
                       |> Stream.chunk(2, 1)
                       |> Enum.take(2)
                       |> Enum.map(fn [a, b] -> b - a end)
    assert div(delta1 * 100, @interval) in @delta_ratio
    assert div(delta2 * 100, @interval) in @delta_ratio
  end

  test "periodic callback even if callback is slow" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid ->
      :timer.sleep(@wait_for_timeout)
      GenEvent.notify(manager, :os.system_time(:milli_seconds))
    end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [delta1, delta2] = GenEvent.stream(manager)
                       |> Stream.chunk(2, 1)
                       |> Enum.take(2)
                       |> Enum.map(fn [a, b] -> b - a end)
    assert div(delta1 * 100, @interval) in @delta_ratio
    assert div(delta2 * 100, @interval) in @delta_ratio
  end

  @tag capture_log: true
  test "periodic callback even if raise error in a callback" do
    {:ok, manager} = GenEvent.start_link
    callback = fn _pid ->
      GenEvent.notify(manager, :os.system_time(:milli_seconds))
      raise "boom!"
    end
    {:ok, _timer} = Petick.Timer.start_link([callback: callback, interval: @interval])
    [delta1, delta2] = GenEvent.stream(manager)
                       |> Stream.chunk(2, 1)
                       |> Enum.take(2)
                       |> Enum.map(fn [a, b] -> b - a end)
    assert div(delta1 * 100, @interval) in @delta_ratio
    assert div(delta2 * 100, @interval) in @delta_ratio
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

  test "change interval from frequently to infrequently" do
    old_interval = @interval
    new_interval = @interval * 3

    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: old_interval])

    result = GenEvent.stream(manager)
             |> Enum.reduce_while([], fn i, acc ->
               # interval:   | new | changed | old |
               # list    :  [a,    b,        c,    d]
               list = Enum.take([i | acc], 4)
               changed = with b when is_integer(b) <- Enum.at(list, 1),
                              c when is_integer(c) <- Enum.at(list, 2), do: !(div((b - c) * 100, old_interval) in @delta_ratio)

               if length(list) == 2 do # called twice
                 Petick.Timer.change_interval(timer, new_interval)
               end

               if changed do
                 {:halt, list}
               else
                 {:cont, list}
               end
             end)
             |> Enum.chunk(2, 1)
             |> Enum.map(fn [a, b] -> a - b end)

    [new_delta, changed_delta, old_delta] = result
    assert div(new_delta     * 100, new_interval) in @delta_ratio
    assert div(changed_delta * 100, new_interval) in @delta_ratio
    assert div(old_delta     * 100, old_interval) in @delta_ratio
  end

  test "change interval from infrequently to frequently" do
    old_interval = @interval * 3
    new_interval = @interval

    {:ok, manager} = GenEvent.start_link
    callback = fn _pid -> GenEvent.notify(manager, :os.system_time(:milli_seconds)) end
    {:ok, timer} = Petick.Timer.start_link([callback: callback, interval: old_interval])

    result = GenEvent.stream(manager)
             |> Enum.reduce_while([], fn i, acc ->
               # interval:   | new | changed | old |
               # list    :  [a,    b,        c,    d]
               list = Enum.take([i | acc], 4)
               changed = with b when is_integer(b) <- Enum.at(list, 1),
                              c when is_integer(c) <- Enum.at(list, 2), do: !(div((b - c) * 100, old_interval) in @delta_ratio)

               if length(list) == 2 do # called twice
                 Petick.Timer.change_interval(timer, new_interval)
               end

               if changed do
                 {:halt, list}
               else
                 {:cont, list}
               end
             end)
             |> Enum.chunk(2, 1)
             |> Enum.map(fn [a, b] -> a - b end)

    [new_delta, changed_delta, old_delta] = result
    assert div(new_delta     * 100, new_interval) in @delta_ratio
    assert div(changed_delta * 100, new_interval) in @delta_ratio
    assert div(old_delta     * 100, old_interval) in @delta_ratio
  end
end
