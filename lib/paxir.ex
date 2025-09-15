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

      {:sequence_bracket, meta, content} when is_list(content) ->
        build_list(meta, content)

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

      passthrough ->
        passthrough
        # |> IO.inspect(label: "passthrough")
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

  defp get_colon_suffix_atom({atom, _meta, _value}) when is_atom(atom) do
    case String.split(Atom.to_string(atom), ":") do
      [atom, ""] -> String.to_atom(atom)
      _ -> nil
    end
  end

  defp get_colon_suffix_atom(_expr), do: nil

  defp build_dict(meta, pairs) do
    pairs =
      pairs
      |> Enum.chunk_every(2)
      |> Enum.map(fn
        [key_expr, value] ->
          elixir_key =
            case get_colon_suffix_atom(key_expr) do
              nil -> eval_expr(key_expr)
              key -> key
            end

          elixir_value = eval_expr(value)
          {elixir_key, elixir_value}

        [key] ->
          raise "Dict construction requires even number of arguments, got odd key: #{inspect(key)}"
      end)

    {:%{}, meta, pairs}
  end

  defp build_list(_meta, content) do
    content =
      content
      |> Enum.chunk_every(2)
      |> Enum.map(fn
        [key_expr, value] ->
          case get_colon_suffix_atom(key_expr) do
            nil ->
              [eval_expr(key_expr), eval_expr(value)]

            key ->
              [{key, eval_expr(value)}]
          end

        [expr] ->
          [eval_expr(expr)]
      end)
      |> Enum.concat()

    content
  end
end
