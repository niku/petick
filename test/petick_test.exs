defmodule PetickTest do
  use ExUnit.Case, async: true
  doctest Petick

  test "start_child/1" do
    assert {:ok, _pid} = Petick.start_child([[callback: fn x -> IO.inspect x end, interval: 1000]])
  end
end
