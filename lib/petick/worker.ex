defmodule Petick.Worker do
  use GenServer

  def start_link(args, options \\ []) do
    GenServer.start_link(__MODULE__, args, options)
  end
end
