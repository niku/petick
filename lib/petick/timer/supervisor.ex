defmodule Petick.Timer.Supervisor do
  use Supervisor

  def start_link([]) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_args) do
    children = [
      worker(Petick.Timer, [], restart: :temporary)
    ]

    opts = [strategy: :simple_one_for_one]
    supervise(children, opts)
  end
end
