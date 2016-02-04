defmodule Petick do
  use Application

  @supervisor Petick.Timer.Supervisor

  #
  # Client
  #
  def start(args) do
    Supervisor.start_child(@supervisor, [args])
  end

  def list do
    for {:undefined, pid, :worker, [Petick.Timer]} <- Supervisor.which_children(@supervisor), do: pid
  end

  def get(pid) do
    Petick.Timer.get_config(pid)
  end

  def change_interval(pid, interval) when is_integer(interval) and 0 < interval do
    Petick.Timer.change_interval(pid, interval)
  end

  def terminate(pid) do
    Supervisor.terminate_child(@supervisor, pid)
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
