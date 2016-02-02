defmodule Petick do
  use Application

  @supervisor Petick.Timer.Supervisor

  #
  # Client
  #
  def start_child(args) do
    Supervisor.start_child(@supervisor, args)
  end

  def list do
    for {:undefined, pid, :worker, [Petick.Timer]} <- Supervisor.which_children(@supervisor) do
      {config, next_tick} = Petick.Timer.get_config(pid)
      {pid, config, next_tick}
    end
  end

  #
  # Server
  #

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Petick.Worker, [arg1, arg2, arg3]),
      supervisor(@supervisor, []),
      supervisor(Task.Supervisor, [[name: Petick.TaskSupervisor]]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    Supervisor.start_link(children, opts)
  end
end
