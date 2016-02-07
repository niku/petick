# Petick

[![Build Status](https://travis-ci.org/niku/petick.svg?branch=master)](https://travis-ci.org/niku/petick)

Petick is an application for periodic timer which repeatedly calls a function with a fixed time delay between each call. It is built on a top of ErlangVM.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add petick to your list of dependencies in `mix.exs`:

        def deps do
          [{:petick, "~> 0.0.1"}]
        end

  2. Ensure petick is started before your application:

        def application do
          [applications: [:petick]]
        end

## Usage

### Elixir

```elixir
# Starts timer : Petick.start/1
callback = fn pid -> IO.puts "called from #{inspect pid} #{inspect :calendar.now_to_datetime(:os.timestamp)}" end
{:ok, pid} = Petick.start(interval: 10000, callback: callback)
# => {:ok, #PID<0.153.0>}

# callback also can be defined tuple {Module, function}
defmodule Foo do
  def bar(pid) do
    IO.puts "called from #{inspect pid} #{inspect :calendar.now_to_datetime(:os.timestamp)}"
  end
end
{:ok, pid2} = Petick.start(interval: 5000, callback: {Foo, :bar})
# => {:ok, #PID<0.164.0>}

# callback called at estimated time
# => called from #PID<0.153.0> {{2016, 2, 7}, {14, 30, 8}}
# => called from #PID<0.164.0> {{2016, 2, 7}, {14, 30, 12}}
# => called from #PID<0.164.0> {{2016, 2, 7}, {14, 30, 17}}
# => called from #PID<0.153.0> {{2016, 2, 7}, {14, 30, 18}}

# Lists timers : Petick.list/0
Petick.list
# => [#PID<0.164.0>, #PID<0.153.0>]

# Gets timer config : Petick.get/1
Petick.get(pid2)
# => {%Petick.Timer.Config{callback: {Foo, :bar}, interval: 5000}, 3074}

# Terminates timer : Petick.terminate/1
Petick.terminate(pid2)
# => :ok

# Changes interval of a timer : Petick.change_interval/2
Petick.change_interval(pid, 1000)
# => :ok
# => called from #PID<0.153.0> {{2016, 2, 7}, {14, 30, 28}}
# => called from #PID<0.153.0> {{2016, 2, 7}, {14, 30, 29}}
# => called from #PID<0.153.0> {{2016, 2, 7}, {14, 30, 30}}

# tear down
Petick.terminate(pid)
# => :ok
Petick.list
# => []
```

### Erlang

(TBD)

## LICENSE

This software is released under the MIT License, see LICENSE
