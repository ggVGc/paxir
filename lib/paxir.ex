defmodule Paxir do
  defmacro paxir!({:raw_section, _meta, exprs}) do
    {:__block__, [],
     Enum.map(
       exprs,
       fn expr -> eval_expr(expr, Map.keys(__CALLER__.versioned_vars)) end
     )}
  end

  def eval_expr(expr, caller_vars \\ %{}) do
    expr |> IO.inspect(label: "IN")

    case expr do
      {:raw_block, meta, :"()", content} ->
        handle_parens(meta, caller_vars, content)

      {:raw_block, _meta, :{}, content} ->
        content
        |> Enum.map(&eval_expr/1)
        |> List.to_tuple()

      {:raw_block, meta, :"[]", content} ->
        build_list(meta, content)

      {true, _meta, nil} ->
        true

      {false, _meta, nil} ->
        false

      {:raw_token, _meta, nil} ->
        nil

      passthrough ->
        passthrough
        # |> IO.inspect(label: "passthrough")
    end

    # |> IO.inspect(label: "OUT")
  end

  defp handle_parens(meta, _caller_vars, [
         {:fn, fn_meta, _},
         {:raw_block, _block_meta, _, params} | body
       ]) do
    params = Enum.map(params, &eval_expr/1)

    body =
      case Enum.map(body, &eval_expr/1) do
        [single] -> single
        body -> {:__block__, [], body}
      end

    {:fn, meta, [{:->, fn_meta, [params, body]}]}
  end

  defp handle_parens(_meta, _caller_vars, [{def_type, def_meta, _} | args])
       when def_type in [:def, :defp] do
    handle_def(def_type, def_meta, args)
  end

  defp handle_parens(_meta, _caller_vars, [{:%, dict_meta, nil} | args]) do
    build_dict(dict_meta, args)
  end

  defp handle_parens(_meta, caller_vars, [{function_name, fun_meta, ctx} | args]) do
    is_local =
      Enum.any?(caller_vars, fn
        {^function_name, nil} -> true
        _ -> false
      end)

    if is_local do
      {{:., [], [{function_name, [], ctx}]}, [], Enum.map(args, &eval_expr/1)}
    else
      {function_name, fun_meta, Enum.map(args, &eval_expr/1)}
    end
  end

  defp handle_def(def_type, def_meta, [
         {name, _name_meta, ctx},
         {:raw_block, _block_meta, _, params} | body
       ])
       when is_atom(name) do
    params = Enum.map(params, &eval_expr/1)

    body =
      case Enum.map(body, &eval_expr/1) do
        [single] -> single
        body -> {:__block__, [], body}
      end

    {def_type, def_meta, [{name, [context: ctx], params}, [do: body]]}
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
