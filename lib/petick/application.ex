defmodule Petick.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Petick.Timer.Supervisor,
      {Task.Supervisor, name: Petick.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Petick.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
