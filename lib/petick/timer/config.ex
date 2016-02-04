defmodule Petick.Timer.Config do
  defstruct callback: nil, interval: nil
  @type t :: %__MODULE__{callback: (pid -> any()) | {:atom, :atom}, interval: pos_integer()}
end
