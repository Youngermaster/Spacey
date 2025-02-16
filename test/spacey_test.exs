defmodule SpaceyTest do
  use ExUnit.Case
  doctest Spacey

  test "greets the world" do
    assert Spacey.hello() == :world
  end
end
