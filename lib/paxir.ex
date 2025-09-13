defmodule Paxir do
  defmacro paxir!({:sequence_literal, _meta, exprs}) do
    {:__block__, [], Enum.map(exprs, &eval_expr/1)}
  end

  defp eval_expr(expr) do
     case expr do
      {:sequence_paren, _meta, [{:def, def_meta, nil} | args]} ->
        handle_def(def_meta, args)

      {:sequence_paren, _meta, [{function_name, fun_meta, _} | args]} ->
         {function_name, fun_meta, args}

      # let Elixir handle basic types
      passthrough ->
        passthrough
    end
  end

  defp handle_def(_meta, [{name, name_meta, nil}, {:sequence_block, block_meta, _, params} | body])
       when is_atom(name) do
    {:def, block_meta, [{name, name_meta, params}, [do: {:__block__, [], body}]]}
  end
end
