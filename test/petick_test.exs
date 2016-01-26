defmodule PetickTest do
  use ExUnit.Case, async: true
  doctest Petick

  test "start_child/1" do
    assert {:ok, _pid} = Petick.start_child([[]])
  end
end
