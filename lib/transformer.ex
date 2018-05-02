defmodule Transformer do

  defp transform_tree(map, transform_aux) when is_map(map) do
      # take each pair, transform_tree the value, generate a new map from it.
      # then transform the map.
      transform_aux.(for {k, v} <- map, into: %{}, do: {k, transform_tree(v, transform_aux)})
  end

  defp transform_tree(list, transform_aux) when is_list(list) do
      # transform_tree each value generate a new list from it.
      # then transform the list
      transform_aux.(Enum.map(list, fn(val) -> transform_tree(val, transform_aux) end))
  end

  # default to transfroming the value
  defp transform_tree(value, transform_aux) do
    transform_aux.(value)
  end

  def transform_with(method, val) do
    transform_tree(val, method)
  end



end
