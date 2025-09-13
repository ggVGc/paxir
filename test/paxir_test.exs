defmodule PaxirTest do
  use ExUnit.Case
  import Paxir

  paxir! ~~(
    (def identity (a) a)
    (def identity2 (_a b) b)
  )

  test "basic" do
    # assert 3 == paxir! ~~(3)
    # quote do identity end |> IO.inspect(label: "indent fun")
    # assert identity("a") == "a"
    # assert identity2(1, 2) == 2
    assert 2 == paxir! ~~((+ 1 1))
  end
end
