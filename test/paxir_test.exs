defmodule PaxirTest do
  use ExUnit.Case
  import Paxir

  paxir! ~~(
    (def identity (a) a)
    (defp identity2 (_a b) b)

    # Multiple statements in def
    (def double (x)
      (= result (+ x x))
      result)
  )

  test "basic" do
    assert 3 == paxir! ~~(3)
    assert identity("a") == "a"
    assert identity2(1, 2) == 2
    assert 2 == paxir! ~~((+ 1 1))
    assert double(3) == 6

    var = 10
    assert 20 == paxir! ~~((double var))
  end

  test "assignment" do
    paxir! ~~((= added (+ 1 1)))
    assert added == 2
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

  test "dicts" do
    # Explicit tuples
    dict = paxir! ~~((% :a 1 :b 2))
    assert dict == %{a: 1, b: 2}

    # With syntax sugar
    dict = paxir! ~~((% x: 3))
    assert dict == %{x: 3}


    # Variable key
    number = 10
    dict = paxir! ~~((% number "yep"))
    assert dict == %{number => "yep"}
  end
end
