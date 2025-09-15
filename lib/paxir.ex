defmodule Paxir do
  defmacro paxir!({:sequence_literal, _meta, exprs}) do
    {:__block__, [], Enum.map(exprs, &eval_expr/1)}
  end

  defp eval_expr(expr) do
    expr |> IO.inspect(label: "IN")

    case expr do
      {:sequence_paren, _meta, [{:def, def_meta, nil} | args]} ->
        handle_def(:def, def_meta, args)

      {:sequence_paren, _meta, [{:defp, def_meta, nil} | args]} ->
        handle_def(:defp, def_meta, args)

      {:sequence_paren, _meta, [{:%, dict_meta, nil} | args]} ->
        build_dict(dict_meta, args)

      {:sequence_paren, _meta, [{function_name, fun_meta, _} | args]} ->
        {function_name, fun_meta, Enum.map(args, &eval_expr/1)}

      {:sequence_bracket, _meta, content} when is_list(content) ->
        Enum.map(content, &eval_expr/1)

      {:sequence_brace, _meta, content} when is_list(content) ->
        content
        |> Enum.map(&eval_expr/1)
        |> List.to_tuple()

      {:sequence_block, meta, :"()", content} ->
        eval_expr({:sequence_paren, meta, content})

      {:sequence_block, meta, :{}, content} ->
        eval_expr({:sequence_brace, meta, content})

      {true, _meta, nil} ->
        true

      {false, _meta, nil} ->
        false

      {:sequence_token, _meta, nil} ->
        nil

      # let Elixir handle basic types
      passthrough ->
        passthrough
        |> IO.inspect(label: "passthrough")
    end
    |> IO.inspect(label: "OUT")
  end

  defp handle_def(def_type, _meta, [
         {name, name_meta, nil},
         {:sequence_block, block_meta, _, params} | body
       ])
       when is_atom(name) do
    body = Enum.map(body, &eval_expr/1)
    {def_type, block_meta, [{name, name_meta, params}, [do: {:__block__, [], body}]]}
  end

  defp build_dict(meta, args) do
    args =
      args
      |> Enum.chunk_every(2)
      |> Enum.map(fn
        [key, value] ->
          elixir_key = eval_expr(key)
          elixir_value = eval_expr(value)
          {elixir_key, elixir_value}

        [key] ->
          raise "Dict construction requires even number of arguments, got odd key: #{inspect(key)}"
      end)

    {:%{}, meta, args}
  end
end
