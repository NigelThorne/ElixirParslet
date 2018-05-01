defmodule SimpleXML do
  defmodule Parser do
    use Parslet

    rule :text do
      repeat(match("[^<]"), 1)
    end

    rule :tag_name do
      repeat(match("[a-zA-Z0-9_\-]"), 1)
    end

    rule :tag do
      str("<") |> tag_name |> str(">") |> node_ |>
      str("</") |> tag_name |> str(">")
    end

    rule :node_ do
      one_of([
        tag(),
        text(),
      ])
    end

    root :node_
  end


  #default to leaving it untouched
  def transform(any) do
    any
  end

  def transform_tree(map) when is_map(map) do
      # take each pair, transform_tree the value, generate a new map from it.
      # then transform the map.
      transform(for {k, v} <- map, into: %{}, do: {k, transform_tree(v)})
  end

  def transform_tree(list) when is_list(list) do
      # transform_tree each value generate a new list from it.
      # then transform the list
      transform(Enum.map(list, &transform_tree/1))
  end

  # default to transfroming the value
  def transform_tree(value) do
    transform(value)
  end

  def from_string(input) do
    parsed = Parser.parse(input)
    transform_tree(parsed)
  end
end
