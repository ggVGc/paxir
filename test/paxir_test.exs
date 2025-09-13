defmodule PaxirTest do
  use ExUnit.Case
  import Paxir

  paxir! ~~(
    (def identity (a) a)
    (def identity2 (_a b) b)
  )

  test "basic" do
    assert 3 == paxir! ~~(3)
    assert identity("a") == "a"
    assert identity2(1, 2) == 2
    assert 2 == paxir! ~~((+ 1 1))
  end


  test "lists" do
    assert [1, :abc, "a", ~c"b", false, true, nil] == paxir! ~~([1 :abc "a" 'b' false true nil])
    assert [3] == paxir! ~~([(identity 3)])
  end

  test "tuples" do
    assert {1, 2} = paxir! ~~({1 2})
    assert {123, 99} = paxir! ~~({123 (identity 99)})
  end

  test "keyword lists" do
    assert [yeo: 1, other: "yo"] == paxir! ~~([{:yeo 1} {:other "yo"}])
  end

end
