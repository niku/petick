defmodule Petick do
  @supervisor Petick.Timer.Supervisor

  ## Client API

  @doc """
  Starts a timer.
  """
  @spec start([term]) :: {:ok, pid}
  def start(args) do
    Supervisor.start_child(@supervisor, [args])
  end

  @doc """
  Lists pids of timer.
  """
  @spec list() :: [pid]
  def list do
    for {:undefined, pid, :worker, [Petick.Timer]} <- Supervisor.which_children(@supervisor),
        do: pid
  end

  @doc """
  Gets config of the timer.
  """
  @spec get(pid) :: Petick.Timer.Config.t()
  def get(pid) do
    Petick.Timer.get_config(pid)
  end

  @doc """
  Changes interval of the timer.
  """
  @spec change_interval(pid, pos_integer) :: :ok
  def change_interval(pid, interval) when is_integer(interval) and 0 < interval do
    Petick.Timer.change_interval(pid, interval)
  end

  @doc """
  Terminates the timer.
  """
  @spec terminate(pid) :: :ok | {:error, error} when error: :not_found
  def terminate(pid) do
    Supervisor.terminate_child(@supervisor, pid)
  end
end
