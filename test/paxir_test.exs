defmodule PaxirTest do
  use ExUnit.Case
  import Paxir

  paxir!(
    # Multiple statements in def
    ~~(
    (def identity (a) a)
    (defp identity2 (_a b) b)
    (def double (x)
    (= result (+ x x))
    result)
    )
  )

  test "basic" do
    assert 3 == paxir!(~~(3))
    assert identity("a") == "a"
    assert identity2(1, 2) == 2
    assert 2 == paxir!(~~((+ 1 1)))
    assert ~c"a" == paxir!(~~((identity [97])))
    assert double(3) == 6

    var = 10
    assert 20 == paxir!(~~((double var)))
    assert :yeo == paxir!(~~((identity :yeo)))
  end

  test "call function" do
    {:raw_section, _, [expr]} = quote do: ~~((identity 42))
    elixir_expr = quote do: identity(42)
    assert Paxir.eval_expr(expr) == elixir_expr
  end

  test "assignment" do
    paxir!(~~((= added (+ 1 1))))
    assert added == 2
  end

  test "lists" do
    assert [~c"b", 1, :abc, "a", false, true, nil] == paxir!(~~([[98] 1 :abc "a" false true nil]))
    assert [3] == paxir!(~~([(identity 3)]))
  end

  test "tuples" do
    assert {1, 2} = paxir!(~~({1 2}))
    assert {123, 99} = paxir!(~~({123 (identity 99)}))
  end

  test "keyword lists" do
    # Explicit tuples
    assert [yeo: 1, other: "yo"] == paxir!(~~([{:yeo 1} {:other "yo"}]))

    # Syntax sugar
    assert [key: "value", other_key: :other] == paxir!(~~([key: "value" other_key: :other]))
  end

  test "dicts" do
    # Explicit tuples
    dict = paxir!(~~((% :a 1 :b 2)))
    assert dict == %{a: 1, b: 2}

    # With syntax sugar
    dict = paxir!(~~((% x: 3)))
    assert dict == %{x: 3}

    # Variable key
    number = 10
    dict = paxir!(~~((% number "yep")))
    assert dict == %{number => "yep"}

    # Expression key
    dict = paxir!(~~((% (double 2) :yep)))
    assert dict == %{double(2) => :yep}
  end

  describe "pattern match function arguments" do
    test "tuple" do
      {:raw_section, _, [tuple_def]} =
        quote do: ~~((def match_tuple ({a b}) a))

      elixir_tuple_def =
        quote do
          def match_tuple({a, b}) do
            a
          end
        end

      assert Paxir.eval_expr(tuple_def) == elixir_tuple_def
    end

    test "list" do
      {:raw_section, _, [list_def]} =
        quote do: ~~((def match_list ([a b]) a))

      elixir_list_def =
        quote do
          def match_list([a, b]) do
            a
          end
        end

      assert Paxir.eval_expr(list_def) == elixir_list_def
    end

    test "literal" do
      {:raw_section, _, [literal_def]} =
        quote do: ~~((def match_literal (123) 99))

      elixir_literal_def =
        quote do
          def match_literal(123) do
            99
          end
        end

      assert Paxir.eval_expr(literal_def) == elixir_literal_def
    end
  end

  test "anonymous function" do
    {:raw_section, _, [expr]} =
      quote do: ~~((fn (a) (= x a) x))

    elixir_expr =
      quote do
        fn a ->
          x = a
          x
        end
      end

    assert Paxir.eval_expr(expr) == elixir_expr
    anon = paxir!(~~((fn (a) (= x a) x)))
    assert anon.(:yeo) == :yeo
  end

  test "call anonymous function" do
    local_identity = fn x -> x end
    assert :yep == paxir!(~~((local_identity :yep)))
  end
end
